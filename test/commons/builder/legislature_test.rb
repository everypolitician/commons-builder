# frozen_string_literal: true

require 'test_helper'

class LegislatureTest < Minitest::Test
  def wikidata_labels
    Minitest::Mock.new
  end

  def test_popolo_json
    data = {
      area_id:           'Q515',
      house_item_id:     'Q1',
      position_item_id:  'Q44',
      seat_count:        '40',
    }
    wikidata_labels = wikidata_labels
    def wikidata_labels.labels_for(_item)
      { 'lang:en': 'Test legislature' }
    end
    legislature = Legislature.new(**data)
    expected = {
      name:               { 'lang:en': 'Test legislature' },
      id:  'Q1',
      classification:     'branch',
      identifiers:        [{
        scheme: 'wikidata', identifier: 'Q1',
      },],
      area_id:            'Q515',
      seat_counts:        { 'Q44' => '40' },
    }
    assert_equal expected, legislature.as_popolo_json(wikidata_labels)
  end

  def test_popolo_json_does_not_include_empty_seat_count
    data = {
      area_id:           'Q515',
      house_item_id:     'Q1',
      position_item_id:  'Q44',
    }
    wikidata_labels = wikidata_labels
    def wikidata_labels.labels_for(_item)
      { 'lang:en': 'Test legislature' }
    end
    legislature = Legislature.new(**data)
    expected = {
      name:               { 'lang:en': 'Test legislature' },
      id:  'Q1',
      classification:     'branch',
      identifiers:        [{
        scheme: 'wikidata', identifier: 'Q1',
      },],
      area_id:            'Q515',
    }
    assert_equal expected, legislature.as_popolo_json(wikidata_labels)
  end
end
