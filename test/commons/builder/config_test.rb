# frozen_string_literal: true

require 'test_helper'

module Commons
  class ConfigTest < Minitest::Test
    def test_can_access_values_from_hash
      config = Config.new languages: %w[en es]
      assert_equal(%w[en es], config.languages)
    end

    def test_can_access_json_values_from_file
      config = Config.new_from_file('test/fixtures/config/config.json')
      assert_equal('Q23666', config.values[:country_wikidata_id])
    end

    def test_can_access_languages_from_file
      config = Config.new_from_file('test/fixtures/config/config.json')
      assert_equal(%w[en es], config.languages)
    end

    def test_can_access_country_wikidata_id_from_file
      config = Config.new_from_file('test/fixtures/config/config.json')
      assert_equal('Q23666', config.country_wikidata_id)
    end

    def test_can_infer_languages_from_language_map
      config = Config.new_from_file('test/fixtures/config/config-with-language-map.json')
      assert_equal(%w[en es], config.languages)
    end

    def test_no_additional_admin_areas
      config = Config.new_from_file('test/fixtures/config/config.json')
      assert_equal([], config.additional_admin_area_ids)
    end

    def test_additional_admin_areas
      config = Config.new_from_file('test/fixtures/config/config-additional-admin-areas.json')
      assert_equal(%w[Q1 Q2], config.additional_admin_area_ids)
    end

    def test_exclude_admin_areas
      config = Config.new_from_file('test/fixtures/config/config-exclude-admin-areas.json')
      assert_equal(%w[Q1 Q2 Q3], config.exclude_admin_area_ids)
    end
  end
end
