# frozen_string_literal: true

require 'csv'

require_relative 'results'

# This class parses the metadata we have about boundaries associated
# with a particular position (e.g. "Member of Parliament") in this
# repository.

class BoundaryData

  attr_reader :boundaries_dir_path, :index_file, :output_stream
  # Public: Initialize a BoundaryData object
  #
  # wikidata_labels - a WikidataLabels instance
  # options       - a Hash of options (default: {}):
  # Valid options are:
  #       :boundaries_dir - the directory for the boundaries and index file
  #       :index_file - the filename of the index file
  #       :output_stream - IOStream for warnings
  def initialize(wikidata_labels, options = {})
    @wikidata_labels = wikidata_labels
    @boundaries_dir_path = options.fetch(:boundaries_dir){ 'boundaries' }
    @index_file = options.fetch(:index_file){ 'index.json' }
    @output_stream = options.fetch(:output_stream){ $stdout }
  end

  def name_object(name_columns, feature_data)
    name_columns.map do |locale, column|
      [locale, feature_data[column]]
    end.to_h.compact.tap do |names_h|
      raise "No names found from the #{name_columns} columns of #{feature_data}" if names_h.empty?
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

  def ms_fb_id_to_area
    @ms_fb_id_to_area ||= popolo_areas.map do |area|
      [area[:id], area]
    end.to_h
  end

  def all_parents(ms_fb_id)
    area = ms_fb_id_to_area[ms_fb_id]
    results = []
    while area[:parent_id]
      parent_area = ms_fb_id_to_area[area[:parent_id]]
      results.push parent_area
      area = parent_area
    end
    results
  end

  private

  attr_reader :position_item_id

  def popolo_areas_before_parent_mapping
    @popolo_areas_before_parent_mapping ||= index_data.flat_map do |metadata|
      directory = metadata[:directory]

      unless metadata[:area_type_wikidata_item_id]
        output_stream.puts "WARNING: No :area_type_wikidata_item_id entry for" \
                           " #{metadata[:directory]} boundaries"
        next
      end
      area_type_names = wikidata_labels.labels_for(metadata[:area_type_wikidata_item_id])
      name_columns = metadata[:name_columns]
      filter = AreaFilterFactory.for(metadata[:filter])
      shapefile_csv = boundaries_dir.join(directory, "#{directory}.csv")
      CSV.read(shapefile_csv, headers: true).map(&:to_h).map do |feature_data|
        next unless filter.should_include?(feature_data)
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
      end.compact
    end.compact
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
    @ms_fb_to_wikidata ||= wikidata_to_ms_fb.map { |k, v| [v, k] }.to_h
  end

  def boundaries_dir
    @boundaries_dir ||= Pathname.new(boundaries_dir_path)
  end

  def index_json_pathname
    @index_json_pathname ||= boundaries_dir.join(index_file)
  end

  def index_data
    @index_data ||= JSON.parse(index_json_pathname.read, symbolize_names: true)
  end

end
