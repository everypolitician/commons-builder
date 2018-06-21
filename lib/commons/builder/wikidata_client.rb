# frozen_string_literal: true

require 'rest-client'

class WikidataClient
  include SPARQLLanguageHelper

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
end
