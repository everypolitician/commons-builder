# frozen_string_literal: true

module SPARQLLanguageHelper
  # This is a pure function for forming language-dependent SPARQL
  # variable names
  def variable(prefix, lang_code, query = true)
    variable = "#{prefix}_#{lang_code.tr('-', '_')}"
    variable = "?#{variable}" if query
    variable
  end

  # These methods depend on languages being available when mixed in:
  def lang_select(prefix = 'name')
    languages.map { |l| variable(prefix, l) }.join(' ')
  end

  def lang_options(prefix = 'name', item = '?item')
    languages.map do |l|
      "OPTIONAL {
          #{item} rdfs:label #{variable(prefix, l)}
          FILTER(LANG(#{variable(prefix, l)}) = \"#{l}\")
        }"
    end.join("\n")
  end
end
