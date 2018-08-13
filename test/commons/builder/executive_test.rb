# frozen_string_literal: true

require 'test_helper'

class ExecutiveTest < Minitest::Test
  def config(languages: ['en'])
    data = { 'languages': languages, 'country_wikidata_id': 'Q16' }
    Config.new(data)
  end

  def test_as_json_round_trip
    data = {
      comment:           'Test Executive',
      executive_item_id: 'Q1',
      positions:         [{
        position_item_id: 'Q2',
        comment:          'Test position',
      },],
    }
    executive = Executive.new(**data)
    assert_equal data, executive.as_json
  end

  def test_list_with_good_data
    stub_request(:post, 'https://query.wikidata.org/sparql')
      .to_return(body: open('test/fixtures/executive-index.srj', 'r'))

    executives = Executive.list(config)
    assert_equal 3, executives.length
    assert_equal "Queen's Privy Council for Canada", executives[0].comment
    assert_equal 'Q1631137', executives[0].executive_item_id
    assert_equal [Position.new(branch:           executives[0],
                               position_item_id: 'Q839078',
                               comment:          'Prime Minister of Canada'),], executives[0].positions
  end

  def test_list_with_missing_executive
    stub_request(:post, 'https://query.wikidata.org/sparql')
      .to_return(body: open('test/fixtures/executive-index-missing-executive.srj', 'r')).then
      .to_return(body: '[]')

    executives = Executive.list(config)
    assert_equal [], executives
  end

  def test_list_with_missing_position
    stub_request(:post, 'https://query.wikidata.org/sparql')
      .to_return(body: open('test/fixtures/executive-index-missing-position.srj', 'r')).then
      .to_return(body: '[]')

    executives = Executive.list(config)
    assert_equal [], executives
  end

  def test_list_with_two_positions_for_one_executive
    # If an executive is listed in the results more than once, with multiple positions, group those positions into a
    # single executive entry. Also ensure that the entries are sorted by executive and position item IDs.
    stub_request(:post, 'https://query.wikidata.org/sparql')
      .to_return(body: open('test/fixtures/executive-index-two-positions.srj', 'r'))

    executives = Executive.list(config)
    assert_equal 2, executives.length
    assert_equal 'Q2665914', executives[0].executive_item_id
    assert_equal %w[Q22979263 Q23729452], executives[0].positions.map(&:position_item_id)
    assert_equal 'Q32859621', executives[1].executive_item_id
  end
end
