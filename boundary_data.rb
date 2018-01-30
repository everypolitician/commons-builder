# frozen_string_literal: true

require 'csv'

require_relative 'results'

class WikidataLabels
  def item_with_label(wikidata_item_id)
    return '[no item]' if wikidata_item_id.nil?
    "#{label_for(wikidata_item_id)} (#{wikidata_item_id})"
  end

  def label_for(wikidata_item_id)
    all_labels = labels_for(wikidata_item_id)
    return nil if all_labels.nil?
    preferred_language_order = LANGUAGE_MAP.keys
    languages = all_labels.keys.sort_by do |l|
      preferred_language_order.index(l)
    end
    return all_labels.values_at(*languages).first
  end

  def labels_for(wikidata_item_id)
    return labels_cache[wikidata_item_id] if labels_cache.include?(wikidata_item_id)
    from_wikidata = begin
                      fetch_labels(wikidata_item_id)
                    rescue
                      nil
                    end
    labels_cache[wikidata_item_id] = from_wikidata
    from_wikidata
  end

  private

  def labels_cache
    @labels_cache ||= {}
  end

  # This function returns a multilingual name object for a Wikidata item
  def fetch_labels(wikidata_item_id)
    query = <<~SPARQL
        SELECT ?name_en ?name_fr WHERE {
          BIND(wd:#{wikidata_item_id} as ?item)
          OPTIONAL {
            ?item rdfs:label ?name_en
            FILTER(LANG(?name_en) = "en")
          }
          OPTIONAL {
            ?item rdfs:label ?name_fr
            FILTER(LANG(?name_fr) = "fr")
          }
        }
  SPARQL
    result = RestClient.get(URL, params: { query: query, format: 'json' })
    bindings = JSON.parse(result, symbolize_names: true)[:results][:bindings]
    result = Row.new(bindings[0]).name_object('name', LANGUAGE_MAP)
    raise "No language labels found for #{wikidata_item_id}" if result.empty?
    result
  end
end

# This class parses the metadata we have about boundaries associated
# with a particular position (e.g. "Member of Parliament") in this
# repository.

class BoundaryData

  def initialize(wikidata_labels)
    @wikidata_labels = wikidata_labels
  end

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
    @popolo_areas ||= popolo_areas_before_parent_mapping.map do |area|
      cloned_area = area.clone
      cloned_area[:parent_id] = ms_fb_to_wikidata[area[:parent_ms_fb_id]]
      cloned_area.delete(:parent_ms_fb_id)
      cloned_area
    end
  end

  def ms_fb_id(area_wikidata_item_id)
    wikidata_to_ms_fb[area_wikidata_item_id]
  end

  attr_reader :wikidata_labels

  private

  attr_reader :position_item_id

  def popolo_areas_before_parent_mapping
    @popolo_areas_before_parent_mapping ||= index_data.flat_map do |metadata|
      directory = metadata[:directory]
      area_type_names = wikidata_labels.labels_for(metadata[:area_type_wikidata_item_id])
      name_columns = metadata[:name_columns]
      shapefile_csv = boundaries_dir.join(directory, "#{directory}.csv")
      CSV.read(shapefile_csv, headers: true).map(&:to_h).map do |feature_data|
        {
          id: feature_data.fetch('WIKIDATA').tap do |area_id|
            raise "No Wikidata ID found in area row #{feature_data}" if area_id.to_s.empty?
          end,
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
          parent_ms_fb_id: feature_data['MS_FB_PARE'],
        }
      end
    end
  end

  def wikidata_to_ms_fb
    @wikidata_to_ms_fb ||= popolo_areas_before_parent_mapping.map do |area|
      [
        area[:identifiers].find { |i| i[:scheme] == 'wikidata' }[:identifier],
        area[:identifiers].find { |i| i[:scheme] == 'MS_FB' }[:identifier],
      ]
    end.to_h
  end

  def ms_fb_to_wikidata
    @ms_fb_to_wikidata ||= wikidata_to_ms_fb.map { |k,v| [v, k] }.to_h
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
