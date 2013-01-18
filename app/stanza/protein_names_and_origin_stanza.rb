class ProteinNamesAndOriginStanza < StanzaBase
  property :title, 'Names and origin'

  property :genes do |gene_id|
    uniprot_url = uniprot_url(gene_id)

    query(:uniprot, <<-SPARQL)
      PREFIX up: <http://purl.uniprot.org/core/>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

      SELECT DISTINCT ?gene_name ?synonyms_name ?locus_name
      FROM <http://purl.uniprot.org/uniprot/>
      WHERE {
        ?protein rdfs:seeAlso <#{uniprot_url}> .
        ?protein up:reviewed true .

        # Gene names
        ?protein up:encodedBy ?encoded_by .

        ## Name:
        OPTIONAL { ?encoded_by skos:prefLabel ?gene_name . }

        ## Synonyms:
        OPTIONAL { ?encoded_by skos:altLabel ?synonyms_name . }

        ## Ordered Locus Names:
        OPTIONAL { ?encoded_by up:locusName ?locus_name . }
      }
    SPARQL
  end

  property :summary do |gene_id|
    uniprot_url = uniprot_url(gene_id)

    protein_summary = query(:uniprot, <<-SPARQL)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX up: <http://purl.uniprot.org/core/>

      SELECT DISTINCT ?recommended_name ?ec_name ?alternative_names ?organism_name ?taxonomy_id ?parent_taxonomy_names
      FROM <http://purl.uniprot.org/uniprot/>
      WHERE {
        ?protein rdfs:seeAlso <#{uniprot_url}> .
        ?protein up:reviewed true .

        # Protein names
        ## Recommended name:
        OPTIONAL {
          ?protein up:recommendedName ?recommended_name_node .
          ?recommended_name_node up:fullName ?recommended_name .
        }

        ### EC=
        OPTIONAL { ?recommended_name_node up:ecName ?ec_name . }

        OPTIONAL {
          ?protein up:alternativeName ?alternative_names_node .
          ?alternative_names_node up:fullName ?alternative_names .
        }

        # Organism
        ?protein up:organism ?taxonomy_id .

        OPTIONAL { ?taxonomy_id up:scientificName ?organism_name . }

        # Taxonomic identifier

        # Taxonomic lineage
        OPTIONAL {
          # ?taxonomy_id rdfs:subClassOf* ?parent_taxonomy .
          ?taxonomy_id rdfs:subClassOf ?parent_taxonomy .
          ?parent_taxonomy up:scientificName ?parent_taxonomy_names .
        }
      }
    SPARQL

    # [{a: 'hoge', b: 'moge'}, {a: 'hoge', b: 'fuga'}] => {a: 'hoge', b: ['moge', 'fuga']}
    protein_summary = protein_summary.flat_map(&:to_a).group_by(&:first).each_with_object({}) {|(k, vs), hash|
      v = vs.map(&:last).uniq
      hash[k] = v.one? ? v.first : v
    }

    # subClassOf* で順に子から親をたどって取得しているが、順番は逆が良い
    #protein_summary[:parent_taxonomy_names] = protein_summary[:parent_taxonomy_names].reverse
    protein_summary
  end

  def uniprot_url(gene_id)
    query(:togogenome, <<-SPARQL).first[:up]
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
  end
end
