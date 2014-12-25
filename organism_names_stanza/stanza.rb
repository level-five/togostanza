class OrganismNamesStanza < TogoStanza::Stanza::Base
  search :organism_name_list do |query|
    query("http://togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      PREFIX taxo: <http://ddbj.nig.ac.jp/ontologies/taxonomy#>
      PREFIX taxid: <http://identifiers.org/taxonomy/>

      SELECT DISTINCT (REPLACE(STR(?taxonomy),"http://identifiers.org/taxonomy/","") AS ?tax_id)
      FROM <http://togogenome.org/graph/taxonomy/>
      WHERE {
        VALUES ?name_type {
          taxo:scientificName taxo:synonym taxo:preferredSynonym taxo:acronym taxo:preferredAcronym taxo:anamorph taxo:teleo
          taxo:misnomer taxo:commonName taxo:preferredCommonName taxo:inPart taxo:includes taxo:equivalentName
          taxo:genbankSynonym taxo:genbankCommonName taxo:authority taxo:misspelling
        }
        ?taxonomy ?name_type ?name .
        #{text_search_filter(:name, query)}
      }
    SPARQL
  end

  property :organism_name_list do |tax_id|
    results = query("http://togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      PREFIX taxo: <http://ddbj.nig.ac.jp/ontologies/taxonomy#>
      PREFIX taxid: <http://identifiers.org/taxonomy/>

      SELECT ?name_type ?name_type_label ?name
      FROM <http://togogenome.org/graph/taxonomy/>
      WHERE
      {
        VALUES ?name_type
        {
          taxo:scientificName taxo:synonym taxo:preferredSynonym taxo:acronym taxo:preferredAcronym taxo:anamorph taxo:teleomorph
          taxo:misnomer taxo:commonName taxo:preferredCommonName taxo:inPart taxo:includes taxo:equivalentName
          taxo:genbankSynonym taxo:genbankCommonName taxo:authority taxo:misspelling
        }
        taxid:#{ tax_id } ?name_type ?name .
        ?name_type rdfs:label ?name_type_label .
      }
    SPARQL

    result = results.map {|hash|
      name = hash[:name].gsub("\\","")
      name_label = hash[:name_type_label].capitalize
      hash.merge(
        name_label: name_label,
        name: name
      )
    }.group_by {|hash| hash[:name_type] }

    #Order by kind of synonym
    order_array = ["scientificName", "synonym", "preferredSynonym", "acronym", "preferredAcronym",
                   "anamorph", "teleomorph", "misnomer", "commonName", "preferredCommonName",
                   "inPart", "includes", "equivalentName", "genbankSynonym", "genbankCommonName", "authority", "misspelling" ]
    taxo_prefix = "http://ddbj.nig.ac.jp/ontologies/taxonomy#"
    orderd_result = []
    hoge = order_array.each {|item|
      key = taxo_prefix + item
      unless result[key].nil? then
        orderd_result.push(result[key])
      end
    }
    orderd_result
  end
end
