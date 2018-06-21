# frozen_string_literal: true

require 'rest-client'

class WikidataClient
  attr_accessor :url

  def initialize(url: 'https://query.wikidata.org/sparql')
    @url = url
  end

  def perform_raw(sparql_query)
    headers = { 'Content-Type': 'application/sparql-query',
                'Accept':       'application/sparql-results+json', }
    response = RestClient.post(url, sparql_query, headers)
    response.body
  end

  def perform(sparql_query, parser)
    parser.parse(perform_raw(sparql_query))
  end
end
