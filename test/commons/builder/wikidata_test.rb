require 'test_helper'

class Commons::WikidataTest < Minitest::Test

  def test_accepts_languages
    languages = ["en"]
    wikidata = Wikidata.new(languages)
    assert_equal(languages, wikidata.languages)
  end

  def test_lang_select_returns_space_delimited_names
    languages = ["en"]
    wikidata = Wikidata.new(languages)
    expected = "?name_en"
    assert_equal(expected, wikidata.lang_select)
  end

  def test_lang_select_converts_hypens
    languages = ["zh-tw"]
    wikidata = Wikidata.new(languages)
    expected = "?name_zh_tw"
    assert_equal(expected, wikidata.lang_select)
  end

  def test_lang_options_returns_optional_filter
    languages = ["en"]
    wikidata = Wikidata.new(languages)
    expected = <<-EOF
OPTIONAL {
          ?item rdfs:label ?name_en
          FILTER(LANG(?name_en) = "en")
        }
EOF
    assert_equal(expected.strip, wikidata.lang_options)
  end

  def test_lang_options_converts_hypens
    languages = ["zh-tw"]
    wikidata = Wikidata.new(languages)
    expected = <<-EOF
OPTIONAL {
          ?item rdfs:label ?name_zh_tw
          FILTER(LANG(?name_zh_tw) = "zh-tw")
        }
EOF
    assert_equal(expected.strip, wikidata.lang_options)
  end
end
