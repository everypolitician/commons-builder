class Wikidata

  attr_accessor :language_map

  def initialize(language_map)
    @language_map = language_map
  end

  def lang_select(prefix='name')
    language_map.values.map { |l| "?#{prefix}_#{l}" }.join(' ')
  end

  def lang_options(prefix='name', item='?item')
    language_map.values.map do |l|
      "OPTIONAL {
          #{item} rdfs:label ?#{prefix}_#{l}
          FILTER(LANG(?#{prefix}_#{l}) = \"#{l}\")
        }"
    end.join("\n")
  end

end
