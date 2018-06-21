# frozen_string_literal: true

class WikidataResultsParser
  # Creates WikidataRow objects out of the parsed JSON from the
  # Wikidata Query Service.

  def initialize(languages:)
    @languages = languages
  end

  def parse(query_response)
    JSON.parse(query_response, symbolize_names: true)[:results][:bindings].map do |row|
      WikidataRow.new(row, languages)
    end
  end

  private

  attr_reader :languages
end
