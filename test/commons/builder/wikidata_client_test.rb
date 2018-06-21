# frozen_string_literal: true

require 'test_helper'

module Commons
  class WikidataClientTest < Minitest::Test
    def test_accepts_url
      wikidata_client = WikidataClient.new(url: 'http://example.com')
      assert_equal(wikidata_client.url, 'http://example.com')
    end

    def test_has_a_default_url
      wikidata_client = WikidataClient.new
      assert_equal(wikidata_client.url, 'https://query.wikidata.org/sparql')
    end
  end
end
