# frozen_string_literal: true

class WikidataLabels
  def initialize(config:, wikidata_client:)
    @config = config
    @wikidata_client = wikidata_client
  end

  def item_with_label(wikidata_item_id)
    return '[no item]' if wikidata_item_id.nil?
    "#{label_for(wikidata_item_id)} (#{wikidata_item_id})"
  end

  def label_for(wikidata_item_id)
    all_labels = labels_for(wikidata_item_id)
    return nil if all_labels.nil?
    label_languages = all_labels.keys.sort_by do |l|
      config.languages.index(l)
    end
    all_labels.values_at(*label_languages).first
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

  attr_reader :wikidata_client, :config

  def labels_cache
    @labels_cache ||= {}
  end

  def parser
    @parser ||= WikidataResultsParser.new(languages: config.languages)
  end

  # This function returns a multilingual name object for a Wikidata item
  def fetch_labels(wikidata_item_id)
    query = WikidataQueries.new(config).templated_query('labels', wikidata_item_id: wikidata_item_id)
    results = wikidata_client.perform(query, parser)
    result = results[0].name_object('name')
    raise "No language labels found for #{wikidata_item_id}" if result.empty?
    result
  end
end
