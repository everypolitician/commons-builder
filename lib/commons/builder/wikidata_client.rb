# frozen_string_literal: true

require 'rest-client'

class WikidataClient
  attr_accessor :url

  def initialize(url: 'https://query.wikidata.org/sparql')
    @url = url
  end

  def perform(sparql_query, parser)
    headers = { 'Content-Type': 'application/sparql-query',
                'Accept':       'application/sparql-results+json', }
    result = RestClient.post(url, sparql_query, headers)
    parser.parse(result)
  end
end
