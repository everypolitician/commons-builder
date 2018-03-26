require 'test_helper'

class Commons::WikidataResultsTest < Minitest::Test

  def test_row_name_object_extracts_simple_values
    data = { :party_name_en => { :"xml:lang" => "en",
                                 :type => "literal",
                                 :value => "Kuomintang" }
            }
    language_map = {
      "lang:en_US": "en"
    }
    row = WikidataRow.new(data, language_map)
    expected = { :"lang:en_US" => "Kuomintang" }
    assert_equal(expected, row.name_object('party_name'))
  end

end
