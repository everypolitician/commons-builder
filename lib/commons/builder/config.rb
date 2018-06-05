# frozen_string_literal: true

require 'json'
require 'pathname'

class Config
  attr_reader :values

  def initialize(values)
    @values = values
  end

  def self.new_from_file(filename)
    Config.new(JSON.parse(Pathname.new(filename).read,
                          symbolize_names: true))
  end

  def languages
    @languages ||= begin
      if values[:languages]
        values[:languages]
      else
        puts 'WARNING: config.json should now use a list of language codes'
        values[:language_map].values
      end
    end
  end

  def country_wikidata_id
    @country_wikidata_id ||= values[:country_wikidata_id]
  end

  def additional_admin_area_ids
    @additional_admin_area_ids ||= values[:additional_admin_area_ids] || []
  end

  def to_liquid
    # These variables are available in liquid templates
    {
      'additional_admin_area_ids' => additional_admin_area_ids,
      'country_wikidata_id' => country_wikidata_id,
      'languages' => languages,
    }
  end
end
