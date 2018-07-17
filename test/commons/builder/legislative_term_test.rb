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

  def test_extra_serialization
    # Any unknown parameters should be serialized verbatim
    term = { comment: 'Term', term_item_id: 'Q3', position_item_id: 'Q5678',
             number_of_seats: 5, building_name: 'Big Building', }
    legislature = Legislature.new terms: [term], house_item_id: 'Q1',
                                  position_item_id: 'Q1234', comment: 'Test legislature'
    assert_equal term, legislature.terms[0].as_json
  end
end
