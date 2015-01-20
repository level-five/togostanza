class ProteinOrthologsStanza < TogoStanza::Stanza::Base
  property :orthologs do |refseq_id, gene_id|
    protein_attributes = query("http://dev.togogenome.org/sparql-test", <<-SPARQL.strip_heredoc)
      SELECT (REPLACE(STR(?id_upid),"http://identifiers.org/uniprot/","http://purl.uniprot.org/uniprot/") AS ?upid)
      FROM <http://togogenome.org/graph/tgup>
      WHERE
      {
        <http://togogenome.org/gene/#{refseq_id}:#{gene_id}> rdfs:seeAlso ?id_upid .
        ?id_upid a <http://identifiers.org/uniprot> .
      }
    SPARQL

    if protein_attributes.nil? || protein_attributes.size.zero?
      next nil
    end

    uniprot_uri = protein_attributes.first[:upid]

#   Uses temporary endpoint due to maintenance
#   ortholog_uris = query("http://sparql.nibb.ac.jp/sparql", <<-SPARQL.strip_heredoc)
    ortholog_uris = query("http://mbgd.genome.ad.jp:8047/sparql", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mbgd: <http://mbgd.genome.ad.jp/owl/mbgd.owl#>
      PREFIX orth: <http://mbgd.genome.ad.jp/owl/ortholog.owl#>
      PREFIX uniprot: <http://purl.uniprot.org/uniprot/>
      PREFIX uniprotCore: <http://purl.uniprot.org/core/>

      SELECT DISTINCT ?protein
      WHERE
      {
        ?group a mbgd:Cluster, mbgd:Default ;
          orth:member/mbgd:gene/mbgd:uniprot <#{uniprot_uri}> ;
          orth:member/mbgd:gene/mbgd:uniprot ?protein .
      }
    SPARQL

    if ortholog_uris.nil? || ortholog_uris.size.zero?
      next nil
    end

    ortholog_uris.map {|hash|
      hash[:protein_label] = hash[:protein].gsub('http://purl.uniprot.org/uniprot/','')
    }
    ortholog_uris.last[:is_last_data] = true
    ortholog_uris
  end
end
