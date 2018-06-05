# frozen_string_literal: true

require 'test_helper'

class WikidataQueriesTest < Minitest::Test
  def test_lang_select_expected_result
    lang_options = WikidataQueries::LangSelect.parse('lang_select', "'name' ", nil, Liquid::ParseContext.new)
    context_data = { 'languages' => %w[en es] }
    context = Liquid::Context.new context_data
    expected = '?name_en ?name_es'
    assert_equal(expected, lang_options.render(context))
  end

  def test_lang_options_expected_result
    lang_options = WikidataQueries::LangOptions.parse('lang_options', "'name' '?item' ", nil, Liquid::ParseContext.new)
    context_data = { 'languages' => %w[en es] }
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
    wikidata_queries = WikidataQueries.new languages
    template = "{% lang_select 'party' %}"
    expected = '?party_en ?party_zh_tw'
    assert_equal expected, wikidata_queries.templated_query_from_string('q1', template)
  end

  def test_lang_options_expected_result_in_render
    languages = %w[en zh-tw]
    wikidata_queries = WikidataQueries.new languages
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
    wikidata_queries = WikidataQueries.new languages
    assert_equal 'abc', wikidata_queries.templated_query_from_string('q3', 'a{{ foo }}c', foo: 'b')
  end

  def test_templated_query_with_string_options
    languages = %w[en es]
    wikidata_queries = WikidataQueries.new languages
    assert_equal 'abc', wikidata_queries.templated_query_from_string('q4', 'a{{ foo }}c', 'foo' => 'b')
  end

  def test_templated_query_has_languages_available
    languages = %w[en es]
    wikidata_queries = WikidataQueries.new languages
    template = '{% for l in languages %}{{ l }}{% unless forloop.last %}, {% endunless %}{% endfor %}'
    assert_equal 'en, es', wikidata_queries.templated_query_from_string('q5', template)
  end
end