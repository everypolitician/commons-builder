# frozen_string_literal: true

require 'json'
require 'pathname'


class Config
  attr_reader :values

  def initialize(file)
    @values = JSON.parse(
      Pathname.new(file).read,
      symbolize_names: true
    )
  end

  def languages
    @languages ||= begin
      if values[:languages]
        values[:languages]
      else
        puts "WARNING: config.json should now use a list of language codes"
        values[:language_map].values
      end
    end
  end

  def country_wikidata_id
    @country_wikidata_id ||= values[:country_wikidata_id]
  end
end
