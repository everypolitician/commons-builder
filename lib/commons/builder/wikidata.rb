# frozen_string_literal: true

require 'rest-client'

class Wikidata
  attr_accessor :config, :url

  def initialize(config, url: 'https://query.wikidata.org/sparql')
    @config = config
    @url = url
  end

  def languages
    config.languages
  end

  def perform(sparql_query)
    headers = { 'Content-Type': 'application/sparql-query',
                'Accept':       'application/sparql-results+json', }
    result = RestClient.post(url, sparql_query, headers)
    bindings = JSON.parse(result, symbolize_names: true)[:results][:bindings]
    bindings.map { |row| WikidataRow.new(row, languages) }
  end

  def lang_select(prefix = 'name')
    languages.map { |l| variable(prefix, l) }.join(' ')
  end

  def variable(prefix, lang_code, query = true)
    variable = "#{prefix}_#{lang_code.tr('-', '_')}"
    variable = "?#{variable}" if query
    variable
  end

  def lang_options(prefix = 'name', item = '?item')
    languages.map do |l|
      "OPTIONAL {
          #{item} rdfs:label #{variable(prefix, l)}
          FILTER(LANG(#{variable(prefix, l)}) = \"#{l}\")
        }"
    end.join("\n")
  end
end
