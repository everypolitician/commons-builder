require 'test_helper'

class Commons::WikidataTest < Minitest::Test

  def test_accepts_language_map
    language_map = { "lang:en_US": "en" }
    wikidata = Wikidata.new(language_map)
    assert_equal(language_map, wikidata.language_map)
  end

  def test_lang_select_returns_space_delimited_names
    language_map = { "lang:en_US": "en" }
    wikidata = Wikidata.new(language_map)
    expected = "?name_en"
    assert_equal(expected, wikidata.lang_select)
  end

  def test_lang_options_returns_optional_filter
    language_map = { "lang:en_US": "en" }
    wikidata = Wikidata.new(language_map)
    expected = <<-EOF
OPTIONAL {
          ?item rdfs:label ?name_en
          FILTER(LANG(?name_en) = "en")
        }
EOF
    assert_equal(expected.strip, wikidata.lang_options)
  end

end
