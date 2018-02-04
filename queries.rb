def date_condition(start_date, end_date)
  return '' unless start_date
  end_date ||= '9999-12-31'
  <<~DATE_CONDITION
    BIND(COALESCE(?start, "1000-01-01T00:00:00Z"^^xsd:dateTime) AS ?start_or_sentinel)
    BIND(COALESCE(?end, "9999-12-31T00:00:00Z"^^xsd:dateTime) AS ?end_or_sentinel)
    FILTER (?end_or_sentinel >= "#{start_date}"^^xsd:dateTime)
    FILTER (?start_or_sentinel <= "#{end_date}"^^xsd:dateTime)
DATE_CONDITION
end

def term_condition(term_item_id)
  return '' unless term_item_id
  "?statement pq:P2937 wd:#{term_item_id} ."
end

def query_legislative(position_item_id:, house_item_id:, term_item_id: nil, start_date: nil, end_date: nil, **_)
  unless !!term_item_id ^ !!(start_date and end_date)
    raise 'You must specify either a term item or a start and end date (and not both)'
  end
  <<~SPARQL
    SELECT ?statement
           ?item ?name_en ?name_fr
           ?party ?party_name_en ?party_name_fr
           ?district ?district_name_en ?district_name_fr
           ?role ?role_en ?role_fr
           ?start ?end ?facebook
           ?org ?org_en ?org_fr ?org_jurisdiction
    WHERE {
      BIND(wd:#{position_item_id} as ?role) .
      BIND(wd:#{house_item_id} as ?org) .
      OPTIONAL {
        ?org rdfs:label ?org_en
        FILTER(LANG(?org_en) = "en")
      }
      OPTIONAL {
        ?org rdfs:label ?org_fr
        FILTER(LANG(?org_fr) = "fr")
      }
      OPTIONAL {
        ?org wdt:P1001 ?org_jurisdiction
      }
      ?item p:P39 ?statement .
      OPTIONAL {
        ?item rdfs:label ?name_en
        FILTER(LANG(?name_en) = "en")
      }
      OPTIONAL {
        ?item rdfs:label ?name_fr
        FILTER(LANG(?name_fr) = "fr")
      }
      ?statement ps:P39 ?role .
      OPTIONAL {
        ?role rdfs:label ?role_en
        FILTER(LANG(?role_en) = "en")
      }
      OPTIONAL {
        ?role rdfs:label ?role_fr
        FILTER(LANG(?role_fr) = "fr")
      }
      #{term_condition(term_item_id)}
      OPTIONAL { ?statement pq:P580 ?start }
      OPTIONAL { ?statement pq:P582 ?end }
      OPTIONAL {
        ?statement pq:P768 ?district.
        OPTIONAL {
          ?district rdfs:label ?district_name_en
          FILTER(LANG(?district_name_en) = "en")
        }
        OPTIONAL {
          ?district rdfs:label ?district_name_fr
          FILTER(LANG(?district_name_fr) = "fr")
        }
      }
      OPTIONAL {
        ?statement pq:P4100 ?party.
        OPTIONAL {
          ?party rdfs:label ?party_name_en
          FILTER(LANG(?party_name_en) = "en")
        }
        OPTIONAL {
          ?party rdfs:label ?party_name_fr
          FILTER(LANG(?party_name_fr) = "fr")
        }
      }
      OPTIONAL { ?item wdt:P2013 ?facebook }
      #{date_condition(start_date, end_date)}
    } ORDER BY ?item ?role #{term_item_id ? '?term ' : ''}?start ?end
SPARQL
end

def query_executive(executive_item_id:, positions:, **_)
  space_separated_role_superclass = positions.map { |p| "wd:#{p[:position_item_id]}" }.join(' ')
  <<~SPARQL
    SELECT ?statement ?item ?name_en ?name_fr ?party ?party_name_en ?party_name_fr ?district ?district_name_en ?district_name_fr ?role ?role_en ?role_fr ?start ?end ?role_superclass ?role_superclass_en ?role_superclass_fr ?facebook ?org ?org_en ?org_fr ?org_jurisdiction WHERE {
      VALUES ?role_superclass { #{space_separated_role_superclass} }
      BIND(wd:#{executive_item_id} AS ?org)
      OPTIONAL {
        ?org rdfs:label ?org_en
        FILTER(LANG(?org_en) = "en")
      }
      OPTIONAL {
        ?org rdfs:label ?org_fr
        FILTER(LANG(?org_fr) = "fr")
      }
      OPTIONAL {
        ?org wdt:P1001 ?org_jurisdiction
      }
      ?item p:P39 ?statement .
      OPTIONAL {
        ?item rdfs:label ?name_en
        FILTER(LANG(?name_en) = "en")
      }
      OPTIONAL {
        ?item rdfs:label ?name_fr
        FILTER(LANG(?name_fr) = "fr")
      }
      ?statement ps:P39 ?role .
      OPTIONAL {
        ?role rdfs:label ?role_en
        FILTER(LANG(?role_en) = "en")
      }
      OPTIONAL {
        ?role rdfs:label ?role_fr
        FILTER(LANG(?role_fr) = "fr")
      }
      ?role wdt:P279* ?role_superclass .
      OPTIONAL {
        ?role_superclass rdfs:label ?role_superclass_en
        FILTER(LANG(?role_superclass_en) = "en")
      }
      OPTIONAL {
        ?role_superclass rdfs:label ?role_superclass_fr
        FILTER(LANG(?role_superclass_fr) = "fr")
      }
      ?role wdt:P361 ?org .
      OPTIONAL {
        ?role wdt:P1001 ?district .
        OPTIONAL {
          ?district rdfs:label ?district_name_en
          FILTER(LANG(?district_name_en) = "en")
        }
        OPTIONAL {
          ?district rdfs:label ?district_name_fr
          FILTER(LANG(?district_name_fr) = "fr")
        }
      }
      OPTIONAL { ?statement pq:P580 ?start }
      OPTIONAL { ?statement pq:P582 ?end }
      BIND(COALESCE(?end, "9999-12-31T00:00:00Z"^^xsd:dateTime) AS ?end_or_sentinel)
      FILTER(?end_or_sentinel >= NOW())
      # Find any current party membership:
      OPTIONAL {
        ?item p:P102 ?party_statement .
        ?party_statement ps:P102 ?party .
        OPTIONAL {
          ?party rdfs:label ?party_name_en
          FILTER(LANG(?party_name_en) = "en")
        }
        OPTIONAL {
          ?party rdfs:label ?party_name_fr
          FILTER(LANG(?party_name_fr) = "fr")
        }
        OPTIONAL { ?party_statement pq:P582 ?end_party }
        BIND(COALESCE(?end_party, "9999-12-31T00:00:00Z"^^xsd:dateTime) AS ?party_end_or_sentinel)
        FILTER(?party_end_or_sentinel >= NOW())
      }
      OPTIONAL { ?item wdt:P2013 ?facebook }
    } ORDER BY ?item ?role ?start ?end
SPARQL
end
