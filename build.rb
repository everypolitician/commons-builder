# frozen_string_literal: true

require 'rest-client'
require 'json'

URL = 'https://query.wikidata.org/sparql'

LANGUAGE_MAP = {
  'lang:en_CA' => 'en',
  'lang:fr_CA' => 'fr',
}.freeze

query = <<~SPARQL
  SELECT ?statement
         ?item ?name_en ?name_fr
         ?party ?party_name_en ?party_name_fr
         ?district ?district_name_en ?district_name_fr
         ?role ?role_en ?role_fr
         ?start ?end ?facebook
  WHERE {
    BIND(wd:Q15964890 as ?role) .
    ?item p:P39 ?statement ;
          rdfs:label ?name_en, ?name_fr .
    ?role rdfs:label ?role_en, ?role_fr .
    FILTER(LANG(?role_en) = "en").
    FILTER(LANG(?role_fr) = "fr").
    ?statement ps:P39 ?role ; pq:P2937 wd:Q21157957 .
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
  } ORDER BY ?name_en ?name_fr ?item
SPARQL

class Cell
  def initialize(value_h)
    @value_h = value_h
  end

  def value
    return raw_value.split('/').last if wikidata_item?
    return raw_value.to_s[0...10] if date?
    raw_value
  end

  private

  attr_reader :value_h

  def wikidata_item?
    type == 'uri' and raw_value.start_with?('http://www.wikidata.org/entity/Q')
  end

  def date?
    datatype == 'http://www.w3.org/2001/XMLSchema#dateTime'
  end

  def raw_value
    value_h[:value]
  end

  def type
    value_h[:type]
  end

  def datatype
    value_h[:datatype]
  end
end

class Row
  def initialize(row_h)
    @row_h = row_h
  end

  def [](key)
    return unless row_h[key]
    Cell.new(row_h[key])
  end

  def name_object(var_prefix, language_map)
    language_map.map do |key_lang, wikidata_lang|
      [
        key_lang,
        self["#{var_prefix}_#{wikidata_lang}".to_sym].value,
      ]
    end.to_h
  end

  private

  attr_reader :row_h
end

result = RestClient.get(URL, params: { query: query, format: 'json' })
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

organizations = membership_rows.map do |membership|
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

areas = membership_rows.map do |membership|
  {
    name: membership.name_object('district_name', LANGUAGE_MAP),
    id: membership[:district].value,
    identifiers: [
      {
        scheme: 'wikidata',
        identifier: membership[:district].value,
      },
    ],
    type: {
      'lang:en_CA': 'federal electoral district of Canada',
      'lang:fr_CA': 'circonscription électorale fédérale canadienne',
    },
    parent_id: 'Q16',
  }
end.uniq

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
    on_behalf_of_id: membership[:party].value,
    area_id: membership[:district].value,
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

puts JSON.pretty_generate(all_data)
