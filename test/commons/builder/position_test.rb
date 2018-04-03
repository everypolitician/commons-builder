# frozen_string_literal: true

require 'test_helper'

class PositionTest < Minitest::Test
  def test_as_json_expected_result
    position = Position.new(branch: Executive.new, comment: 'President', position_item_id: 'Q1')
    expected_json = {
      comment:          'President',
      position_item_id: 'Q1'
    }
    assert_equal expected_json, position.as_json
  end
end
