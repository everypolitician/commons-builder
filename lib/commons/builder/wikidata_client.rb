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
    reorder_bindings response.body
  end

  def perform(sparql_query, parser)
    parser.parse(perform_raw(sparql_query))
  end

  private

  def reorder_bindings(result)
    # The Wikidata query service doesn't always return bindings in resultsets
    # in a consistent order, so we shall order them as per .head.vars so as
    # not to produce spurious diffs
    result = JSON.parse(result, symbolize_names: true)
    vars = result[:head][:vars].map(&:to_sym)
    result[:results][:bindings] = result[:results][:bindings].map do |bindings|
      vars.map { |k| [k, bindings[k]] if bindings[k] }.compact.to_h
    end
    JSON.pretty_generate result
  end
end
