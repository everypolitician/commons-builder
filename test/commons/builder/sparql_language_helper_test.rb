# frozen_string_literal: true

require 'test_helper'

module Commons
  class SPARQLLanguageHelperTest < Minitest::Test
    class FakeWithLanguages
      include SPARQLLanguageHelper
      def initialize(languages)
        @languages = languages
      end
      attr_reader :languages
    end

    def test_lang_select_returns_space_delimited_names
      fake_with_languages = FakeWithLanguages.new(['en'])
      expected = '?name_en'
      assert_equal(expected, fake_with_languages.lang_select)
    end

    def test_lang_select_converts_hypens
      fake_with_languages = FakeWithLanguages.new(['zh-tw'])
      expected = '?name_zh_tw'
      assert_equal(expected, fake_with_languages.lang_select)
    end

    def test_lang_options_returns_optional_filter
      fake_with_languages = FakeWithLanguages.new(['en'])
      expected = <<~OPTIONAL_CLAUSE
        OPTIONAL {
                  ?item rdfs:label ?name_en
                  FILTER(LANG(?name_en) = "en")
                }
      OPTIONAL_CLAUSE
      assert_equal(expected.strip, fake_with_languages.lang_options)
    end

    def test_lang_options_converts_hypens
      fake_with_languages = FakeWithLanguages.new(['zh-tw'])
      expected = <<~OPTIONAL_CLAUSE
        OPTIONAL {
                  ?item rdfs:label ?name_zh_tw
                  FILTER(LANG(?name_zh_tw) = "zh-tw")
                }
      OPTIONAL_CLAUSE
      assert_equal(expected.strip, fake_with_languages.lang_options)
    end
  end
end
