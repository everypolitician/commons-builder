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

legislative_dir = Pathname.new(__FILE__).dirname.join('legislative')
index_file = legislative_dir.join('index.json')

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

def query(position_item_id:, term_item_id: nil, start_date: nil, end_date: nil, **_)
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
      ?item p:P39 ?statement ;
            rdfs:label ?name_en, ?name_fr .
      ?role rdfs:label ?role_en, ?role_fr .
      FILTER(LANG(?role_en) = "en").
      FILTER(LANG(?role_fr) = "fr").
      ?statement ps:P39 ?role .
      #{term_condition(term_item_id)}
      OPTIONAL { ?statement pq:P580 ?start }
      OPTIONAL { ?statement pq:P582 ?end }
      OPTIONAL {
        ?statement pq:P768 ?district.
        ?district rdfs:label ?district_name_en, ?district_name_fr .
        FILTER(LANG(?district_name_en) = "en").
        FILTER(LANG(?district_name_fr) = "fr").
      }
      OPTIONAL {
        ?statement pq:P4100 ?party.
        ?party rdfs:label ?party_name_en, ?party_name_fr .
        FILTER(LANG(?party_name_en) = "en").
        FILTER(LANG(?party_name_fr) = "fr").
      }
      OPTIONAL { ?item wdt:P2013 ?facebook }
      FILTER(LANG(?name_en) = "en").
      FILTER(LANG(?name_fr) = "fr").
      #{date_condition(start_date, end_date)}
    } ORDER BY ?name_en ?name_fr ?item
SPARQL
end

boundary_data = BoundaryData.new

JSON.parse(index_file.read, symbolize_names: true).each do |legislature_h|
  legislature_dir = legislative_dir.join(legislature_h[:house_item_id])
  output_pathname = legislature_dir.join('popolo-m17n.json')

  sparql_query = query(**legislature_h)
  legislature_dir.join('query-used.rq').write(sparql_query)

  query_params = {
    query: sparql_query,
    format: 'json',
  }
  result = RestClient.get(URL, params: query_params)
  data = JSON.parse result, symbolize_names: true

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

  areas = membership_rows.select do |membership|
    membership[:district]
  end.map do |membership|
    district_item_id = membership[:district].value
    {
      name: membership.name_object('district_name', LANGUAGE_MAP),
      id: membership[:district].value,
      identifiers: [
        {
          scheme: 'wikidata',
          identifier: district_item_id,
        },
        {
          scheme: 'MS_FB',
          identifier: boundary_data.ms_fb_id(district_item_id),
        },
      ],
      type: {
        'lang:en_CA': 'federal electoral district of Canada',
             'lang:fr_CA': 'circonscription électorale fédérale canadienne',
      },
      parent_id: 'Q16',
    }
  end.uniq

  # Now add any areas we know about from the boundary data, but which
  # isn't associated with a membership yet.
  district_wikidata_ids_seen = Set.new(areas.map { |a| a[:id] })
  areas += boundary_data.popolo_areas.reject do |a|
    district_wikidata_ids_seen.include?(a[:id]) ||
      !a[:associated_wikidata_positions].include?(legislature_h[:position_item_id])
  end

  area_country = {
    name: {
      'lang:en_CA': 'Canada',
           'lang:fr_CA': 'Canada',
    },
    id: 'Q16',
    identifiers: [
      {
        scheme: 'wikidata',
        identifier: 'Q16',
      },
      {
        scheme: 'MS_FB',
        identifier: 'country:ca',
      },
    ],
    type: {
      'lang:en_CA': 'Country',
           'lang:fr_CA': 'Pays',
    },
  }

  memberships = membership_rows.map do |membership|
    {
      id: membership[:statement].value,
      person_id: membership[:item].value,
      on_behalf_of_id: membership[:party]&.value,
      area_id: membership[:district]&.value,
      start_date: membership[:start]&.value,
      end_date: membership[:end]&.value,
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
