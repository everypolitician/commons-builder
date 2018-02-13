# frozen_string_literal: true

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
           ?item #{lang_select}
           ?party #{lang_select('party_name')}
           ?district #{lang_select('district_name')}
           ?role #{lang_select('role')}
           ?start ?end ?facebook
           ?org #{lang_select('org')} ?org_jurisdiction
    WHERE {
      BIND(wd:#{position_item_id} as ?role) .
      BIND(wd:#{house_item_id} as ?org) .
      #{lang_options('org')}
      OPTIONAL {
        ?org wdt:P1001 ?org_jurisdiction
      }
      ?item p:P39 ?statement .
      #{lang_options('name')}
      ?statement ps:P39 ?role .
      #{lang_options('role')}
      #{term_condition(term_item_id)}
      OPTIONAL { ?statement pq:P580 ?start }
      OPTIONAL { ?statement pq:P582 ?end }
      OPTIONAL {
        ?statement pq:P768 ?district.
        #{lang_options('district_name')}
      }
      OPTIONAL {
        ?statement pq:P4100 ?party.
        #{lang_options('party_name')
      }
      OPTIONAL { ?item wdt:P2013 ?facebook }
      #{date_condition(start_date, end_date)}
    } ORDER BY ?item ?role #{term_item_id ? '?term ' : ''}?start ?end
SPARQL
end

def query_executive(executive_item_id:, positions:, **_)
  space_separated_role_superclass = positions.map { |p| "wd:#{p[:position_item_id]}" }.join(' ')
  <<~SPARQL
    SELECT ?statement
           ?item #{lang_select}
           ?party #{lang_select('party_name')}
           ?district #{lang_select('district_name')}
           ?role #{lang_select('role')}
           ?start ?end ?facebook
           ?role_superclass #{lang_select('role_superclass')}
           ?org #{lang_select('org') ?org_jurisdiction
    WHERE {
      VALUES ?role_superclass { #{space_separated_role_superclass} }
      BIND(wd:#{executive_item_id} AS ?org)
      #{lang_options('org')}
      OPTIONAL {
        ?org wdt:P1001 ?org_jurisdiction
      }
      ?item p:P39 ?statement .
      #{lang_options('name')}
      ?statement ps:P39 ?role .
      #{lang_options('role')}
      ?role wdt:P279* ?role_superclass .
      #{lang_options('role_superclass')}
      ?role wdt:P361 ?org .
      OPTIONAL {
        ?role wdt:P1001 ?district .
        #{lang_options('district_name')}
      }
      OPTIONAL { ?statement pq:P580 ?start }
      OPTIONAL { ?statement pq:P582 ?end }
      BIND(COALESCE(?end, "9999-12-31T00:00:00Z"^^xsd:dateTime) AS ?end_or_sentinel)
      FILTER(?end_or_sentinel >= NOW())
      # Find any current party membership:
      OPTIONAL {
        ?item p:P102 ?party_statement .
        ?party_statement ps:P102 ?party .
        #{lang_options('party_name')}
        OPTIONAL { ?party_statement pq:P582 ?end_party }
        BIND(COALESCE(?end_party, "9999-12-31T00:00:00Z"^^xsd:dateTime) AS ?party_end_or_sentinel)
        FILTER(?party_end_or_sentinel >= NOW())
      }
      OPTIONAL { ?item wdt:P2013 ?facebook }
    } ORDER BY ?item ?role ?start ?end
SPARQL
end
