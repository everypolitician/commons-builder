# frozen_string_literal: true

require 'test_helper'

class LegislativeTermTest < Minitest::Test
  def test_legislative_term_query_contains_position_item_id
    config = Config.new languages: %w[en es], country_wikidata_id: 'Q16'
    term = { comment: 'Term', term_item_id: 'Q3' }
    legislature = Legislature.new terms: [term], house_item_id: 'Q1',
                                  position_item_id: 'Q1234', comment: 'Test legislature'
    query = legislature.terms[0].query(config)
    assert_match(/\WBIND\(wd:Q1234 as \?role\)\W/, query)
    assert_match(/\WBIND\(wd:Q1234 as \?specific_role\)\W/, query)
  end

  def test_legislative_term_query_contains_term_position_item_id
    # A position_item_id on the term should override one on the legislature, as it's term-specific
    config = Config.new languages: %w[en es], country_wikidata_id: 'Q16'
    term = { comment: 'Term', term_item_id: 'Q3', position_item_id: 'Q5678' }
    legislature = Legislature.new terms: [term], house_item_id: 'Q1',
                                  position_item_id: 'Q1234', comment: 'Test legislature'
    query = legislature.terms[0].query(config)
    assert_match(/\WBIND\(wd:Q1234 as \?role\)\W/, query)
    assert_match(/\WBIND\(wd:Q5678 as \?specific_role\)\W/, query)
  end

  def test_term_as_json
    full_data = { comment: 'Test term',
                  term_item_id: 'Q3',
                  start_date: '2001-02-03',
                  end_date: '2002-03-04', }.to_a
    # Ensure that all combinations of term data are serialized as expected.
    (1..4).flat_map { |n| full_data.combination(n).to_a }.map(&:to_h).each do |data|
      exception_expected = !data[:term_item_id] && !(data[:start_date] && data[:end_date])
      begin
        term = LegislativeTerm.new legislature: nil, **data
      rescue
        assert_equal true, exception_expected
      else
        assert_equal false, exception_expected
        assert_equal data, term.as_json
      end
    end
  end
end
