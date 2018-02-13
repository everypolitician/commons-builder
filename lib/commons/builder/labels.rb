# frozen_string_literal: true

def lang_select(prefix='name')
  LANGUAGE_MAP.values.map { |l| "?#{prefix}_#{l}" }.join(' ')
end

def lang_options(prefix='name', item='?item')
  LANGUAGE_MAP.values.map do |l|
    "OPTIONAL {
        #{item} rdfs:label ?#{prefix}_#{l}
        FILTER(LANG(?#{prefix}_#{l}) = \"#{l}\")
      }"
  end.join("\n")
end

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
    all_labels.values_at(*languages).first
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
    result = RestClient.get(URL, params: { query: query, format: 'json' })
    bindings = JSON.parse(result, symbolize_names: true)[:results][:bindings]
    result = Row.new(bindings[0]).name_object('name', LANGUAGE_MAP)
    raise "No language labels found for #{wikidata_item_id}" if result.empty?
    result
  end
end
