class TaxonomyPlotStanza < Stanza::Base
  property :selected_taxonomy_id do |tax_id|
    tax_id
  end

  resource :taxonomy do
    sequence_list  = []
    habitat_list   = []
    phenotype_list = []
    tax_label_list = []

    sequence_list = query('http://lod.dbcls.jp/openrdf-sesame5l/repositories/togogenome',<<-SPARQL.strip_heredoc)
      PREFIX obo: <http://purl.obolibrary.org/obo/>
      PREFIX insdc: <http://rdf.insdc.org/>

      SELECT ?tax ?size ?num_gene ?num_trna ?num_rrna
      WHERE
      {
        {
          SELECT ?tax (COUNT(?gene) AS ?num_gene) (COUNT(?trna) AS ?num_trna) (COUNT(?rrna) AS ?num_rrna)
          WHERE
          {
            ?seq rdf:type ?obo_type ;
              rdfs:seeAlso ?tax
              FILTER (?obo_type = obo:SO_0000340 || ?obo_type = obo:SO_0000155) .
            ?tax rdf:type insdc:Taxonomy .
            { ?gene obo:so_part_of ?seq ; rdf:type obo:SO_0000704 . }
            UNION
            { ?trna obo:so_part_of ?seq ; rdf:type obo:SO_0000253 . }
            UNION
            { ?rrna obo:so_part_of ?seq ; rdf:type obo:SO_0000252 . }
          }
          GROUP BY ?tax
        }
        {
          SELECT ?tax (SUM(?len) AS ?size)
          WHERE
          {
            ?seq rdf:type ?obo_type ;
              insdc:sequence_length ?len ;
              rdfs:seeAlso ?tax
              FILTER (?obo_type = obo:SO_0000340 || ?obo_type = obo:SO_0000155) .
            ?tax rdf:type insdc:Taxonomy .
          }
          GROUP BY ?tax
        }
      }
    SPARQL

    # SPARQL statement for filtering by tax_id
    tax_filter = 'FILTER (?tax IN ('

    sequence_list.each_with_index do |entity, idx|
      s = entity[:tax]
      tax_filter << 'tax:' << s.slice(s.rindex('/') + 1, s.length)

      tax_filter << ', ' if idx < sequence_list.size - 1
    end

    tax_filter << '))'

    query2 = Thread.new {
      habitat_list =  query('http://lod.dbcls.jp/openrdf-sesame5l/repositories/gold2', <<-SPARQL.strip_heredoc)
        PREFIX meo: <http://purl.jp/bio/11/meo/>
        PREFIX mccv: <http://purl.jp/bio/01/mccv#>
        PREFIX tax: <http://identifiers.org/taxonomy/>

        SELECT ?tax (GROUP_CONCAT(distinct(?label2); SEPARATOR=",") as ?habitat)
        WHERE
        {
          ?gold meo:environmentalDescribed ?envi .
          ?gold mccv:MCCV_000020 ?tax #{tax_filter} .
          ?envi rdf:type ?meo .
          ?meo rdfs:subClassOf* ?meo2 .
          ?meo2 rdfs:subClassOf owl:Thing.
          ?meo2 rdfs:label ?label2 .
        }
        GROUP BY ?tax ORDER BY ?tax ?meo2
      SPARQL
    }

    query3 = Thread.new {
      phenotype_list =  query('http://lod.dbcls.jp/openrdf-sesame5l/repositories/gold2', <<-SPARQL.strip_heredoc)
        PREFIX mpo:<http://purl.jp/bio/01/mpo#>
        PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
        PREFIX tax: <http://identifiers.org/taxonomy/>

        SELECT distinct ?tax ?cell_shape_label ?temp_range_label ?opt_temp ?min_temp ?max_temp ?oxy_req_label ?opt_ph ?min_ph ?max_ph
        WHERE
        {
          ?tax ?p ?o #{tax_filter} .
          OPTIONAL
          {
            ?tax mpo:MPO_10001 ?cell_shape.
            ?cell_shape skos:prefLabel ?cell_shape_label .
          }
          OPTIONAL
          {
            ?tax mpo:MPO_10003 ?temp_range.
            ?temp_range skos:prefLabel ?temp_range_label .
          }
          OPTIONAL { ?tax mpo:MPO_10009 ?opt_temp . }
          OPTIONAL
          {
            ?tax mpo:MPO_10010 ?min_temp .
            ?tax mpo:MPO_10011 ?max_temp .
          }
          OPTIONAL
          {
            ?tax mpo:MPO_10002 ?oxy_req .
            ?oxy_req skos:prefLabel ?oxy_req_label .
          }
          OPTIONAL { ?tax mpo:MPO_10005 ?opt_ph . }
          OPTIONAL
          {
            ?tax mpo:MPO_10006 ?min_ph .
            ?tax mpo:MPO_10007 ?max_ph .
          }
        }
      SPARQL
    }

    query4 = Thread.new {
      tax_label_list =  query('http://lod.dbcls.jp/openrdf-sesame5l/repositories/ncbitaxon', <<-SPARQL.strip_heredoc)
        PREFIX tax: <http://purl.obolibrary.org/obo/NCBITaxon_>

        SELECT ?tax ?label
        WHERE
        {
          ?tax rdfs:label ?label #{tax_filter} .
        }
      SPARQL
    }

    query2.join
    query3.join
    query4.join

    # merge sequence data with habitat data
    habitat_hash = {}

    habitat_list.each do |i|
      habitat_hash[i[:tax]] = i
    end

    sequence_list.each do |i|
      if habitat_hash[i[:tax]] && habitat_hash[i[:tax]][:habitat]
        i[:habitat] = habitat_hash[i[:tax]][:habitat]
      end
    end

    # merge taxonomy sequence data with phenotype data
    phenotype_hash = {}

    phenotype_list.each do |i|
      phenotype_hash[i[:tax]] = i
    end

    items = [:cell_shape_label, :temp_range_label, :oxy_req_label, :opt_temp, :min_temp, :max_temp, :opt_ph, :min_ph, :max_ph ]

    sequence_list.each do |i|
      items.each do |item|
        if phenotype_hash[i[:tax]] && phenotype_hash[i[:tax]][item]
          i[item] = phenotype_hash[i[:tax]][item]
        end
      end
    end

    # merge sequence data with taxonomy label
    tax_label_hash = {}

    tax_label_list.each do |i|
      tax_id = i[:tax].gsub('http://purl.obolibrary.org/obo/NCBITaxon_', 'http://identifiers.org/taxonomy/')
      tax_label_hash[tax_id] = i
    end

    sequence_list.each do |i|
      if tax_label_hash[i[:tax]] && tax_label_hash[i[:tax]][:label]
        i[:label] = tax_label_hash[i[:tax]][:label]
      end
    end
  end
end
