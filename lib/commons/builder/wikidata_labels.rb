# frozen_string_literal: true

class WikidataLabels < WikidataClient
  def item_with_label(wikidata_item_id)
    return '[no item]' if wikidata_item_id.nil?
    "#{label_for(wikidata_item_id)} (#{wikidata_item_id})"
  end

  def label_for(wikidata_item_id)
    all_labels = labels_for(wikidata_item_id)
    return nil if all_labels.nil?
    label_languages = all_labels.keys.sort_by do |l|
      languages.index(l)
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

  def labels_cache
    @labels_cache ||= {}
  end

  # This function returns a multilingual name object for a Wikidata item
  def fetch_labels(wikidata_item_id)
    query = <<~SPARQL
      SELECT #{lang_select} WHERE {
        BIND(wd:#{wikidata_item_id} as ?item)
        #{lang_options}
      }
  SPARQL
    results = perform(query)
    result = results[0].name_object('name')
    raise "No language labels found for #{wikidata_item_id}" if result.empty?
    result
  end
end
