# frozen_string_literal: true

require 'test_helper'

module Commons
  class WikidataResultsTest < Minitest::Test
    def test_row_name_object_extracts_simple_values
      data = { party_name_en: { "xml:lang": 'en',
                                type: 'literal',
                                value: 'Kuomintang', }, }
      languages = ['en']
      row = WikidataRow.new(data, languages)
      expected = { "lang:en": 'Kuomintang' }
      assert_equal(expected, row.name_object('party_name'))
    end

    def test_row_name_object_extracts_hyphenated_wikidata_lang_values
      data = { party_name_en: { "xml:lang": 'en',
                                type: 'literal',
                                value: 'Kuomintang', },
               party_name_zh_tw: { "xml:lang": 'zh-tw',
                                   type: 'literal',
                                   value: '中國國民黨', }, }
      languages = ['zh-tw', 'en']
      row = WikidataRow.new(data, languages)
      expected = { "lang:en": 'Kuomintang', "lang:zh-tw": '中國國民黨' }
      assert_equal(expected, row.name_object('party_name'))
    end

    def test_extract_boolean
      data = { true: { type: 'literal',
                       value: 'true',
                       datatype: 'http://www.w3.org/2001/XMLSchema#boolean'},
               false: { type: 'literal',
                       value: 'false',
                       datatype: 'http://www.w3.org/2001/XMLSchema#boolean'}, }
      languages = ['en']
      row = WikidataRow.new(data, languages)
      assert_equal(true, row[:true].value)
      assert_equal(false, row[:false].value)
    end
  end
end
