# frozen_string_literal: true

# Classes for handling the JSON-formatted results from the Wikidata
# query service https://query.wikidata.org/

class Cell
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

class Row

  attr_accessor :language_map

  def initialize(row_h, language_map)
    @row_h = row_h
    @language_map = language_map
  end

  def [](key)
    return unless row_h[key]
    Cell.new(row_h[key])
  end

  def name_object(var_prefix)
    language_map.map do |key_lang, wikidata_lang|
      column = "#{var_prefix}_#{wikidata_lang}".to_sym
      [
        key_lang,
        self[column]&.value,
      ]
    end.to_h.compact
  end

  private

  attr_reader :row_h
end
