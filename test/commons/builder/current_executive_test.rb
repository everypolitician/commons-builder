# frozen_string_literal: true

require 'test_helper'

class CurrentExecutiveTest < Minitest::Test
  def test_current_executive_query_contains_position
    config = Config.new languages: %w[en es], country_wikidata_id: 'Q16'

    executive = Executive.new comment:           'Test Executive',
                              executive_item_id: 'Q1',
                              positions:         [{ position_item_id: 'Q1234', comment: 'Test position' }]

    query = executive.terms[0].query(config)
    assert_match(/\Wwd:Q1234\W/, query)
  end
end
