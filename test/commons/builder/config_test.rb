# frozen_string_literal: true

require 'test_helper'

class Commons::ConfigTest < Minitest::Test
  def test_can_access_json_values
    config = Config.new('test/fixtures/config/config.json').values
    assert_equal('Q23666', config[:country_wikidata_id])
  end
end
