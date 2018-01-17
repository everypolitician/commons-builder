# frozen_string_literal: true

require 'csv'

require_relative 'results'

# This function returns a multilingual name object for a Wikidata item
def labels(wikidata_item_id)
  query = <<~SPARQL
      SELECT ?name_en ?name_fr WHERE {
      BIND(wd:#{wikidata_item_id} as ?item)
      ?item rdfs:label ?name_en, ?name_fr .
      FILTER(LANG(?name_en) = "en").
      FILTER(LANG(?name_fr) = "fr").
    }
SPARQL
  result = RestClient.get(URL, params: { query: query, format: 'json' })
  bindings = JSON.parse(result, symbolize_names: true)[:results][:bindings]
  raise "0 rows found when looking for multi-lingual labels of #{wikidata_item_id}" if bindings.empty?
  raise "BUG: more than one row of labels found for #{wikidata_item_id}" if bindings.length > 1
  Row.new(bindings[0]).name_object('name', LANGUAGE_MAP)
end

# This class parses the metadata we have about boundaries associated
# with a particular position (e.g. "Member of Parliament") in this
# repository.

class BoundaryData

  def name_object(name_columns, feature_data)
    name_columns.map do |locale, column|
      [locale, feature_data[column]]
    end.to_h.compact.tap do |names_h|
      if names_h.empty?
        raise "No names found from the #{name_columns} columns of #{feature_data}"
      end
    end
  end

  def popolo_areas
    @popolo_areas ||= index_data.flat_map do |metadata|
      directory = metadata[:directory]
      area_type_names = labels(metadata[:area_type_wikidata_item_id])
      name_columns = metadata[:name_columns]
      shapefile_csv = boundaries_dir.join(directory, "#{directory}.csv")
      CSV.read(shapefile_csv, headers: true).map(&:to_h).map do |feature_data|
        {
          id: feature_data['WIKIDATA'],
          identifiers: [
            {
              scheme: 'MS_FB',
              identifier: feature_data['MS_FB'],
            },
            {
              scheme: 'wikidata',
              identifier: feature_data['WIKIDATA'],
            },
          ],
          associated_wikidata_positions: metadata[:associations].map do |a|
            a[:position_item_id]
          end,
          type: area_type_names,
          name: name_object(name_columns, feature_data),
        }
      end
    end
  end

  def ms_fb_id(area_wikidata_item_id)
    wikidata_to_ms_fb[area_wikidata_item_id]
  end

  private

  attr_reader :position_item_id

  def wikidata_to_ms_fb
    @wikidata_to_ms_fb ||= popolo_areas.map do |area|
      [
        area[:identifiers].find { |i| i[:scheme] == 'wikidata' }[:identifier],
        area[:identifiers].find { |i| i[:scheme] == 'MS_FB' }[:identifier],
      ]
    end.to_h
  end

  def boundaries_dir
    @boundaries_dir ||= Pathname.new(__FILE__).dirname.join('..', 'boundaries')
  end

  def index_json_pathname
    @index_json_pathname ||= boundaries_dir.join('index.json')
  end

  def index_data
    @index_data ||= JSON.parse(index_json_pathname.read, symbolize_names: true)
  end
end
