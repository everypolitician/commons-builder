# frozen_string_literal: true

require 'test_helper'

class WikidataQueriesTest < Minitest::Test
  def config(languages: ['en'])
    data = { 'languages': languages, 'country_wikidata_id': 'Q16' }
    Config.new(data)
  end

  def test_lang_select_expected_result
    lang_options = WikidataQueries::LangSelect.parse('lang_select', "'name' ", nil, Liquid::ParseContext.new)
    context_data = { 'config' => config(languages: %w[en es]) }
    context = Liquid::Context.new context_data
    expected = '?name_en ?name_es'
    assert_equal(expected, lang_options.render(context))
  end

  def test_lang_options_expected_result
    lang_options = WikidataQueries::LangOptions.parse('lang_options', "'name' '?item' ", nil, Liquid::ParseContext.new)
    context_data = { 'config' => config(languages: %w[en es]) }
    context = Liquid::Context.new context_data
    expected = <<~CLAUSE
      OPTIONAL {
        ?item rdfs:label ?name_en
        FILTER(LANG(?name_en) = "en")
      }

      OPTIONAL {
        ?item rdfs:label ?name_es
        FILTER(LANG(?name_es) = "es")
      }
    CLAUSE
    assert_equal(expected, lang_options.render(context))
  end

  def test_lang_select_expected_result_in_render
    languages = %w[en zh-tw]
    wikidata_queries = WikidataQueries.new config(languages: languages)
    template = "{% lang_select 'party' %}"
    expected = '?party_en ?party_zh_tw'
    assert_equal expected, wikidata_queries.templated_query_from_string('q1', template)
  end

  def test_lang_options_expected_result_in_render
    languages = %w[en zh-tw]
    wikidata_queries = WikidataQueries.new config(languages: languages)
    template = "{% lang_options 'party_name' '?party' %}"
    expected = <<~CLAUSE
      OPTIONAL {
        ?party rdfs:label ?party_name_en
        FILTER(LANG(?party_name_en) = "en")
      }

      OPTIONAL {
        ?party rdfs:label ?party_name_zh_tw
        FILTER(LANG(?party_name_zh_tw) = "zh-tw")
      }
    CLAUSE
    assert_equal expected, wikidata_queries.templated_query_from_string('q2', template)
  end

  def test_templated_query_with_sym_options
    languages = %w[en es]
    wikidata_queries = WikidataQueries.new config(languages: languages)
    assert_equal 'abc', wikidata_queries.templated_query_from_string('q3', 'a{{ foo }}c', foo: 'b')
  end

  def test_templated_query_with_string_options
    languages = %w[en es]
    wikidata_queries = WikidataQueries.new config(languages: languages)
    assert_equal 'abc', wikidata_queries.templated_query_from_string('q4', 'a{{ foo }}c', 'foo' => 'b')
  end

  def test_templated_query_has_languages_available
    languages = %w[en es]
    wikidata_queries = WikidataQueries.new config(languages: languages)
    template = '{% for l in config.languages %}{{ l }}{% unless forloop.last %}, {% endunless %}{% endfor %}'
    assert_equal 'en, es', wikidata_queries.templated_query_from_string('q5', template)
  end

  def test_label_service_has_all_langs
    languages = %w[es en zh-tw]
    wikidata_queries = WikidataQueries.new config(languages: languages)
    template = "{% include 'label_service' %}"
    expected = 'SERVICE wikibase:label { bd:serviceParam wikibase:language "en,es,zh-tw". }'
    assert_equal expected, wikidata_queries.templated_query_from_string('q5', template)
  end

  def test_additional_areas_in_admin_areas
    wikidata_queries = WikidataQueries.new Config.new(languages: ['en'],
                                                      country_wikidata_id: 'Q16',
                                                      additional_admin_area_ids: %w[Q1234 Q1235])
    assert_match(/\(wd:Q1234 4 wd:Q24238356\)\s+\(wd:Q1235 4 wd:Q24238356\)/,
                 wikidata_queries.templated_query('select_admin_areas_for_country'))
  end
end
