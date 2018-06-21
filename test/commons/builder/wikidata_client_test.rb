# frozen_string_literal: true

require 'test_helper'

module Commons
  class WikidataTest < Minitest::Test
    def config(languages: ['en'])
      data = { 'languages': languages, 'country_wikidata_id': 'Q16' }
      Config.new(data)
    end

    def test_accepts_config
      wikidata = WikidataClient.new config(languages: %w[en es])
      assert_equal(%w[en es], wikidata.languages)
    end
  end
end
