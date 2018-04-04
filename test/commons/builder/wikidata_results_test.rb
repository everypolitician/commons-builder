require 'test_helper'

class Commons::WikidataResultsTest < Minitest::Test

  def test_row_name_object_extracts_simple_values
    data = { :party_name_en => { :"xml:lang" => "en",
                                 :type => "literal",
                                 :value => "Kuomintang" }
            }
    languages = ["en"]
    row = WikidataRow.new(data, languages)
    expected = { "lang:en" => "Kuomintang" }
    assert_equal(expected, row.name_object('party_name'))
  end

  def test_row_name_object_extracts_hyphenated_wikidata_lang_values
    data = { :party_name_en => { :"xml:lang" => "en",
                                 :type => "literal",
                                 :value => "Kuomintang" },
             :party_name_zh_tw =>  { :"xml:lang" => "zh-tw",
                                    :type => "literal",
                                    :value => "中國國民黨" }
            }
    languages = ["zh-tw", "en"]
    row = WikidataRow.new(data, languages)
    expected = { "lang:en" => "Kuomintang", "lang:zh-tw" => "中國國民黨" }
    assert_equal(expected, row.name_object('party_name'))
  end

end
