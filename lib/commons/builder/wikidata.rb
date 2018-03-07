# frozen_string_literal: true

require 'rest-client'

class Wikidata
  attr_accessor :language_map, :url

  def initialize(language_map, url: 'https://query.wikidata.org/sparql')
    @language_map = language_map
    @url = url
  end

  def perform(sparql_query)
    headers = { 'Content-Type': 'application/sparql-query',
                'Accept':       'application/sparql-results+json' }
    result = RestClient.post(url, sparql_query, headers)
    bindings = JSON.parse(result, symbolize_names: true)[:results][:bindings]
    bindings.map { |row| Row.new(row) }
  end

  def lang_select(prefix='name')
    language_map.values.map { |l| variable(prefix, l) }.join(' ')
  end

  def variable(prefix, lang_code)
    "?#{prefix}_#{lang_code.gsub('-', '_')}"
  end

  def lang_options(prefix='name', item='?item')
    language_map.values.map do |l|
      "OPTIONAL {
          #{item} rdfs:label #{variable(prefix, l)}
          FILTER(LANG(#{variable(prefix, l)}) = \"#{l}\")
        }"
    end.join("\n")
  end

end
