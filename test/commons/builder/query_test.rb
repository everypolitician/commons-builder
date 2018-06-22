# frozen_string_literal: true

require 'test_helper'
require 'webmock/minitest'

module Commons
  class QueryTest < Minitest::Test
    def test_query_used_pn_with_default_basename
      query = Query.new(
        sparql_query: 'some query',
        output_dir_pn: Pathname.new('/foo')
      )
      assert_equal(query.query_used_pn, Pathname.new('/foo/query-used.rq'))
    end

    def test_query_results_pn_with_default_basename
      query = Query.new(
        sparql_query: 'some query',
        output_dir_pn: Pathname.new('/foo')
      )
      assert_equal(query.query_results_pn, Pathname.new('/foo/query-results.json'))
    end

    def test_query_used_pn_with_custom_basename
      query = Query.new(
        sparql_query: 'some query',
        output_dir_pn: Pathname.new('/foo'),
        output_fname_prefix: 'bar-'
      )
      assert_equal(query.query_used_pn, Pathname.new('/foo/bar-query-used.rq'))
    end

    def test_query_results_pn_with_custom_basename
      query = Query.new(
        sparql_query: 'some query',
        output_dir_pn: Pathname.new('/foo'),
        output_fname_prefix: 'bar-'
      )
      assert_equal(query.query_results_pn, Pathname.new('/foo/bar-query-results.json'))
    end

    def test_run
      stub_request(:post, 'https://query.wikidata.org/sparql')
        .to_return(body: '{"results": {"bindings": []}}')
      Dir.mktmpdir do |tmpdir|
        output_dir_pn = Pathname.new(tmpdir)
        query = Query.new(
          sparql_query: 'some query',
          output_dir_pn: output_dir_pn
        )
        results = query.run(wikidata_client: WikidataClient.new)
        assert_equal(
          output_dir_pn.join('query-results.json').read,
          '{"results": {"bindings": []}}'
        )
        assert_equal(
          output_dir_pn.join('query-used.rq').read,
          'some query'
        )
        assert_equal(results, '{"results": {"bindings": []}}')
      end
    end

    def test_last_saved_results
      Dir.mktmpdir do |tmpdir|
        output_dir_pn = Pathname.new(tmpdir)
        query = Query.new(
          sparql_query: 'some query',
          output_dir_pn: output_dir_pn,
          output_fname_prefix: 'bar-'
        )
        # Put some example content in the expected place:
        output_dir_pn.join('bar-query-results.json').write('{"foo": "bar"}')
        assert_equal(query.last_saved_results, '{"foo": "bar"}')
      end
    end
  end
end
