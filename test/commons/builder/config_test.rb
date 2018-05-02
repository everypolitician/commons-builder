# frozen_string_literal: true

require 'test_helper'

class Commons::ConfigTest < Minitest::Test
  def test_can_access_json_values
    config = Config.new('test/fixtures/config/config.json')
    assert_equal('Q23666', config.values[:country_wikidata_id])
  end

  def test_can_access_languages
    config = Config.new('test/fixtures/config/config.json')
    assert_equal(%w[en es], config.languages)
  end

  def test_can_access_country_wikidata_id
    config = Config.new('test/fixtures/config/config.json')
    assert_equal('Q23666', config.country_wikidata_id)
  end

  def test_can_infer_languages_from_language_map
    config = Config.new('test/fixtures/config/config-with-language-map.json')
    assert_equal(%w[en es], config.languages)
  end
end
