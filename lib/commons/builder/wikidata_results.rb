# frozen_string_literal: true

# Classes for handling the JSON-formatted results from the Wikidata
# query service https://query.wikidata.org/

class WikidataCell < Wikidata

  def initialize(value_h)
    @value_h = value_h
  end

  def value
    return raw_value.split('/').last if wikidata_item?
    return raw_value.to_s[0...10] if date?
    raw_value
  end

  private

  attr_reader :value_h

  def wikidata_item?
    type == 'uri' and raw_value.start_with?('http://www.wikidata.org/entity/Q')
  end

  def date?
    datatype == 'http://www.w3.org/2001/XMLSchema#dateTime'
  end

  def raw_value
    value_h[:value]
  end

  def type
    value_h[:type]
  end

  def datatype
    value_h[:datatype]
  end
end

class WikidataRow < Wikidata

  attr_accessor :languages

  def initialize(row_h, languages)
    @row_h = row_h
    @languages = languages
  end

  def [](key)
    return unless row_h[key]
    WikidataCell.new(row_h[key])
  end

  def name_object(var_prefix)
    languages.map do |wikidata_lang|
      column = variable(var_prefix, wikidata_lang, false).to_sym
      [
        :"lang:#{wikidata_lang}",
        self[column]&.value,
      ]
    end.to_h.compact
  end

  private

  attr_reader :row_h
end
