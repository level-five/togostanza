class ProteinAttributesStanza < StanzaBase
  property :title do |gene_id|
    "Protein Attributes : #{gene_id}"
  end

  property :attributes do |gene_id|
    uniprot_url = query(:togogenome, <<-SPARQL).first[:up]
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX insdc: <http://rdf.insdc.org/>

      SELECT ?up
      WHERE {
        ?s insdc:feature_locus_tag "#{gene_id}" .
        ?s rdfs:seeAlso ?np .
        ?np rdf:type insdc:Protein .
        ?np rdfs:seeAlso ?up .
      }
    SPARQL

    protein_attributes = query(:uniprot, <<-SPARQL)
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX up: <http://purl.uniprot.org/core/>

      SELECT DISTINCT ?sequence ?fragment ?existence_label
      FROM <http://purl.uniprot.org/uniprot/>
      WHERE {
        ?protein rdfs:seeAlso <#{uniprot_url}> .
        ?protein up:reviewed true .

        # Sequence length
        OPTIONAL {
          ?protein up:sequence ?seq .
          ?seq rdf:value ?sequence .
        }

        # Sequence status
        OPTIONAL {
          ?seq up:fragment ?fragment .
        }

        # TODO: Sequence processing

        # Protein existence
        OPTIONAL {
          ?protein up:existence ?existence .
          ?existence rdfs:label ?existence_label .
        }
      }
    SPARQL

    # こういうロジック(length, sequence_status)をこっちに持つのはどうなんだろう?
    # でも,UniProt では取れ無さそう(?)
    # 要ご相談
    protein_attributes.map {|attrs|
      attrs.merge(
        sequence_length: attrs[:sequence].try(:length),
        sequence_status: sequence_status(attrs[:fragment].to_s)
      )
    }
  end

  private

  def sequence_status(fragment)
    case fragment
    when 'single', 'multiple'
      'Fragment'
    else
      'Complete'
    end
  end
end