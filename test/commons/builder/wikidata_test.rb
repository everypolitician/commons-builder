# frozen_string_literal: true

require 'test_helper'

module Commons
  class WikidataTest < Minitest::Test
    def config(languages: ['en'])
      data = { 'languages': languages, 'country_wikidata_id': 'Q16' }
      Config.new(data)
    end

    def test_accepts_config
      wikidata = Wikidata.new config(languages: %w[en es])
      assert_equal(%w[en es], wikidata.languages)
    end

    def test_lang_select_returns_space_delimited_names
      languages = ['en']
      wikidata = Wikidata.new config(languages: languages)
      expected = '?name_en'
      assert_equal(expected, wikidata.lang_select)
    end

    def test_lang_select_converts_hypens
      languages = ['zh-tw']
      wikidata = Wikidata.new config(languages: languages)
      expected = '?name_zh_tw'
      assert_equal(expected, wikidata.lang_select)
    end

    def test_lang_options_returns_optional_filter
      languages = ['en']
      wikidata = Wikidata.new config(languages: languages)
      expected = <<~OPTIONAL_CLAUSE
        OPTIONAL {
                  ?item rdfs:label ?name_en
                  FILTER(LANG(?name_en) = "en")
                }
      OPTIONAL_CLAUSE
      assert_equal(expected.strip, wikidata.lang_options)
    end

    def test_lang_options_converts_hypens
      languages = ['zh-tw']
      wikidata = Wikidata.new config(languages: languages)
      expected = <<~OPTIONAL_CLAUSE
        OPTIONAL {
                  ?item rdfs:label ?name_zh_tw
                  FILTER(LANG(?name_zh_tw) = "zh-tw")
                }
      OPTIONAL_CLAUSE
      assert_equal(expected.strip, wikidata.lang_options)
    end
  end
end
