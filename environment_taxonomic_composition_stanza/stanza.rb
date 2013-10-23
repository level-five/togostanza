class EnvironmentTaxonomicCompositionStanza < TogoStanza::Stanza::Base
  property :search_meo_id do |meo_id|
    meo_id
  end

  resource :taxonomy_sunburst do |meo_id|
    results = query(:togogenome, <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>
      PREFIX taxo: <http://ddbj.nig.ac.jp/ontologies/taxonomy#>
      PREFIX taxid: <http://identifiers.org/taxonomy/>

      SELECT ?tax ?organism_name AS ?tax_label ?parent ?rank
      FROM <http://togogenome.org/graph/meo/>
      FROM <http://togogenome.org/graph/gold/>
      FROM <http://togogenome.org/graph/taxonomy/>
      WHERE
      {
        {
          SELECT ?tax
          {
            VALUES ?meo_mapping { meo:MEO_0000437 meo:MEO_0000440 }
            ?meo_id rdfs:subClassOf* meo:#{meo_id} .
            ?gold ?meo_mapping ?meo_id .
            ?gold mccv:MCCV_000020 ?hit_tax FILTER (STRSTARTS(STR(?hit_tax), "http://identifiers.org/taxonomy" )) .
            ?hit_tax rdfs:subClassOf* ?tax .
          } GROUP BY ?tax
        }
        ?tax taxo:scientificName ?organism_name .
        OPTIONAL { ?tax rdfs:subClassOf ?parent . }
        OPTIONAL { ?tax taxo:rank ?rank . }
      }
    SPARQL

    root = {:tax => "http://identifiers.org/taxonomy/1", :tax_label => "root", :definition => "root", :parent => "root"}
    results.push(root)
    results.map {|hash|
      hash[:rank] = (hash[:rank]?hash[:rank].gsub('http://ddbj.nig.ac.jp/ontologies/taxonomy#', ''):'').gsub('NoRank','')
      hash.merge(
        :tag_id => hash[:tax].split('/').last.split('#').last,
        :link => "http://biointegra.jp/OpenID/?tax=" + hash[:tax].split('/').last.split('#').last
      )
    }
  end
end
