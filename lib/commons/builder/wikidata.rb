class Wikidata

  attr_accessor :language_map

  def initialize(language_map)
    @language_map = language_map
  end

  def lang_select(prefix='name')
    language_map.values.map { |l| variable(prefix, l) }.join(' ')
  end

  def variable(prefix, lang_code)
    "?#{prefix}_#{lang_code.gsub('-', '_')}"
  end

  def lang_options(prefix='name', item='?item')
    language_map.values.map do |l|
      "OPTIONAL {
          #{item} rdfs:label #{variable(prefix, l)}
          FILTER(LANG(#{variable(prefix, l)}) = \"#{l}\")
        }"
    end.join("\n")
  end

end
