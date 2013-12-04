require 'net/http'
require 'uri'

class NucleotideSequenceStanza < TogoStanza::Stanza::Base
  property :nucleotide_sequences do |tax_id, gene_id|
    results = query("http://ep.dbcls.jp/sparql7upd2", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX obo:    <http://purl.obolibrary.org/obo/>
      PREFIX faldo:  <http://biohackathon.org/resource/faldo#>
      PREFIX insdc:  <http://ddbj.nig.ac.jp/ontologies/sequence#>

      SELECT DISTINCT ?locus_tag
        (CONCAT("http://togows.dbcls.jp/entry/nucleotide/", replace(?refseq_label,"RefSeq:",""),"/seq/", ?insdc_location) AS ?nuc_seq_pos)
      FROM <http://togogenome.org/graph/refseq/>
      FROM <http://togogenome.org/graph/so/>
      WHERE
      {
        values ?locus_tag { "#{ gene_id }" }
        values ?seq_type  { obo:SO_0000340 obo:SO_0000155 }
        values ?gene_type { obo:SO_0000704 obo:SO_0000252 obo:SO_0000253 }

        ?gene ?p ?locus_tag ;
          a ?gene_type ;
          obo:so_part_of ?seq .
        ?seq a ?seq_type ;
          rdfs:seeAlso ?refseq .
        ?refseq a <http://identifiers.org/refseq/> ;
          rdfs:label ?refseq_label .
        ?gene faldo:location ?faldo .
        ?faldo insdc:location ?insdc_location .
      }
    SPARQL
    results.map {|hash|
      hash.merge(
        :value => get_sequence_from_togows(hash[:nuc_seq_pos]).upcase
      )
    }.first
  end

  #Returns sequence characters from the TogoWS API.
  def get_sequence_from_togows(togows_url)
    url = URI.parse(togows_url)
    path = Net::HTTP::Get.new(url.path)
    Net::HTTP.start(url.host, url.port) {|http|
      res = http.request(path)
      res.body
    }
  end
end
