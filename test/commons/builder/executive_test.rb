# frozen_string_literal: true

require 'test_helper'

class ExecutiveTest < Minitest::Test
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

    languages = ['en']
    executives = Executive.list('Q16', languages)
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

    languages = ['en']
    executives = Executive.list('Q16', languages)
    assert_equal [], executives
  end

  def test_list_with_missing_position
    stub_request(:post, 'https://query.wikidata.org/sparql')
      .to_return(body: open('test/fixtures/executive-index-missing-position.srj', 'r')).then
      .to_return(body: '[]')

    languages = ['en']
    executives = Executive.list('Q16', languages)
    assert_equal [], executives
  end
end
