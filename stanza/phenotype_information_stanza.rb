class PhenotypeInformationStanza < TogoStanza::Stanza::Base
  property :phenotype_items do |tax_id|
    results = query("http://ep.dbcls.jp/sparql", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX up: <http://purl.uniprot.org/core/>
      PREFIX idtax: <http://purl.uniprot.org/taxonomy/>

      SELECT ?mpo ?phenotype (GROUP_CONCAT(?value; SEPARATOR = ", ") AS ?value)
      FROM <http://togogenome.org/mpo/>
      WHERE
      {
        idtax:#{tax_id} ?mpo ?o .
        ?mpo rdfs:label ?phenotype .
        FILTER (lang(?phenotype) = "en") .
        OPTIONAL
        {
          ?o rdfs:label ?o2 .
          FILTER (lang(?o2) = "en") .
        }
        BIND( IF(bound(?o2) ,?o2 , ?o) as ?value )
      } GROUP BY ?mpo ?phenotype ORDER BY ?mpo
    SPARQL

    #add flag for displaying temperature unit
    results.map {|hash|
      mpo_id = hash[:mpo].split('#').last
      if mpo_id == "MPO_10008" || mpo_id == "MPO_10009" || mpo_id == "MPO_10010" then
        hash[:deg_flag] = "true" #flag for adding temperature unit
      end
      hash[:phenotype] = hash[:phenotype][0].upcase + hash[:phenotype][1..-1] #do not use capitalize for 'maximum Ph'
    }
    results
  end
end
