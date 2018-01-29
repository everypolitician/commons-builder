# frozen_string_literal: true

require 'rest-client'
require 'json'

require_relative 'lib/results'
require_relative 'lib/boundary_data'

URL = 'https://query.wikidata.org/sparql'

LANGUAGE_MAP = {
  'lang:en_CA' => 'en',
  'lang:fr_CA' => 'fr',
}.freeze

root_dir = Pathname.new(__FILE__).dirname

COUNTRY_WIKIDATA_ID = 'Q16'

valid_actions = %w(update build)

unknown_args = Set.new(ARGV) - Set.new(valid_actions)
if unknown_args.length > 0
  STDERR.puts "Usage: #{$0} update|build"
  exit(1)
end

actions = valid_actions.clone

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

def query_legislative(position_item_id:, term_item_id: nil, start_date: nil, end_date: nil, **_)
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
    WHERE {
      BIND(wd:#{position_item_id} as ?role) .
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
    SELECT ?statement ?item ?name_en ?name_fr ?party ?party_name_en ?party_name_fr ?district ?district_name_en ?district_name_fr ?role ?role_en ?role_fr ?start ?end ?role_superclass ?role_superclass_en ?role_superclass_fr ?facebook WHERE {
      VALUES ?role_superclass { #{space_separated_role_superclass} }
      BIND(wd:#{executive_item_id} AS ?executive)
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
      ?role wdt:P361 ?executive .
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

def query(entity_kind, political_entity_h)
  if entity_kind == 'legislative'
    query_legislative(**political_entity_h)
  elsif entity_kind == 'executive'
    query_executive(**political_entity_h)
  else
    raise "Unknown political entity kind: #{entity_kind}"
  end
end

# FIXME: writing this at all is further evidence that indicates that
# the political_entity_h variants should be represented by a class
def positions_item_ids(political_entity_h)
  for_legislature = [political_entity_h[:position_item_id]]
  for_executive = political_entity_h.fetch(:positions, []).map { |p| p[:position_item_id] }
  (for_legislature + for_executive).compact
end

boundary_data = BoundaryData.new

['legislative', 'executive'].each do |political_entity_kind|
  political_entity_kind_dir = root_dir.join(political_entity_kind)
  index_file = political_entity_kind_dir.join('index.json')

  JSON.parse(index_file.read, symbolize_names: true).each do |political_entity_h|
    output_relative = political_entity_h[
      {
        "legislative" => :house_item_id,
        "executive" => :executive_item_id,
      }.fetch(political_entity_kind)
    ]
    output_dir = political_entity_kind_dir.join(output_relative)
    output_dir.mkpath
    output_pathname = output_dir.join('popolo-m17n.json')
    raw_results_pathname = output_dir.join('query-results.json')

    if actions.include? 'update'
      sparql_query = query(political_entity_kind, political_entity_h)
      output_dir.join('query-used.rq').write(sparql_query)

      query_params = {
        query: sparql_query,
        format: 'json',
      }
      result = RestClient.get(URL, params: query_params)

      raw_results_pathname.write(result)
    end

    if actions.include?('build')
      data = JSON.parse(raw_results_pathname.read(), symbolize_names: true)

      membership_rows = data[:results][:bindings].map do |row|
        Row.new(row)
      end

      persons = membership_rows.map do |membership|
        {
          name: membership.name_object('name', LANGUAGE_MAP),
          id: membership[:item].value,
          identifiers: [
            {
              scheme: 'wikidata',
              identifier: membership[:item].value,
            },
          ],
          links: [
            {
              note: 'facebook',
              url: membership[:facebook]&.value&.prepend('https://www.facebook.com/'),
            },
          ].select { |o| o[:url] },
        }
      end.uniq

      organizations = membership_rows.select do |membership|
        membership[:party]
      end.map do |membership|
        {
          name: membership.name_object('party_name', LANGUAGE_MAP),
          id: membership[:party].value,
          classification: 'party',
          identifiers: [
            {
              scheme: 'wikidata',
              identifier: membership[:party].value,
            },
          ],
        }
      end.uniq

      # We should have all the relevant areas from the boundary data...
      related_positions = positions_item_ids(political_entity_h)
      areas = boundary_data.popolo_areas.reject do |a|
        (a[:associated_wikidata_positions] & related_positions).empty?
      end
      # ... but warn about any districts found from Wikidata that aren't
      # in that set:
      known_areas = Set.new(areas.map { |a| a[:id] })
      membership_rows.select { |m| m[:district] }.map do |m|
        area_wikidata_id = m[:district].value
        unless known_areas.include?(area_wikidata_id)
          puts "WARNING: the district #{area_wikidata_id} wasn't found in the boundary data for position #{m[:role]&.value}"
        end
      end

      # Check that none of these have a null person_id - we should only
      # allow that for the whole-country area.
      areas_with_bad_parents = areas.select do |area|
        area[:parent_id].nil? && ! area[:id] == COUNTRY_WIKIDATA_ID
      end
      unless areas_with_bad_parents.empty?
        areas_with_bad_parents.each do |area|
          puts "Error: no parent area found for: #{area[:id]}"
        end
        raise "Some areas has a null parent_id"
      end

      area_country = boundary_data.popolo_areas.find { |a| a[:id] == COUNTRY_WIKIDATA_ID }

      memberships = membership_rows.map do |membership|
        {
          id: membership[:statement].value,
          person_id: membership[:item].value,
          on_behalf_of_id: membership[:party]&.value,
          area_id: membership[:district]&.value,
          start_date: membership[:start]&.value,
          end_date: membership[:end]&.value,
          role_superclass_code: membership[:role_superclass]&.value,
          role_superclass: membership[:role_superclass] && membership.name_object('role_superclass', LANGUAGE_MAP),
          role_code: membership[:role].value,
          role: membership.name_object('role', LANGUAGE_MAP),
        }.reject { |_, v| v.to_s.empty? }
      end

      all_data = {
        persons: persons,
        organizations: organizations,
        areas: [area_country] + areas,
        memberships: memberships,
      }

      output_pathname.write(JSON.pretty_generate(all_data) + "\n")
    end
  end
end
