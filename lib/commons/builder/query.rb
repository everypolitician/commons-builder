# frozen_string_literal: true

class Query
  def initialize(sparql_query:, output_dir_pn:, output_fname_prefix: '')
    @sparql_query = sparql_query
    @output_dir_pn = output_dir_pn
    @output_fname_prefix = output_fname_prefix
  end

  def query_used_pn
    output_dir_pn.join(output_fname_prefix + 'query-used.rq')
  end

  def query_results_pn
    output_dir_pn.join(output_fname_prefix + 'query-results.json')
  end

  def last_saved_results
    JSON.parse(query_results_pn.read, symbolize_names: true)
  end

  def run(save_query_used: true, save_query_results: true)
    query_used_pn.write(sparql_query) if save_query_used
    headers = { 'Content-Type': 'application/sparql-query',
                'Accept':       'application/sparql-results+json', }
    result = RestClient.post('https://query.wikidata.org/sparql', sparql_query, headers)
    query_results_pn.write(result) if save_query_results
    JSON.parse(result, symbolize_names: true)
  end

  private

  attr_reader :sparql_query, :output_dir_pn, :output_fname_prefix
end
