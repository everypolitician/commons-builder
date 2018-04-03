class Executive < Branch
  KNOWN_PROPERTIES = %i[comment executive_item_id positions].freeze

  attr_accessor(*KNOWN_PROPERTIES - [:positions])

  def output_relative
    Pathname.new(executive_item_id)
  end

  def positions_item_ids
    positions.map(&:position_item_id)
  end

  def terms
    # We only actually consider current executive positions, but treat
    # this as a "term".
    [CurrentExecutive.new(executive: self)]
  end

  def positions
    @positions.map { |t| Position.new(branch: self, **t) }
  end

  def self.list(country_id, language_map, save_queries: false)
    wikidata_queries = WikidataQueries.new(language_map)
    wikidata_labels = WikidataLabels.new(language_map)
    sparql_query = wikidata_queries.query_executive_index(country_id)

    executives = wikidata_queries.perform(sparql_query)
    open('executive/index-query-used.rq', 'w').write(sparql_query) if save_queries

    executives.select! do |row|
      unless row[:position]&.value
        puts "WARNING: no head of government position for #{wikidata_labels.item_with_label(row[:adminArea].value)}"
        next
      end

      unless row[:executive]&.value
        puts "WARNING: no executive for #{wikidata_labels.item_with_label(row[:position]&.value)} " \
	        "in #{wikidata_labels.item_with_label(row[:adminArea]&.value)}"
        next
      end

      true
    end

    executives.map do |row|
      new(comment:           row[:executiveLabel]&.value,
          executive_item_id: row[:executive].value,
          positions:         [{ comment:          row[:positionLabel]&.value,
                                position_item_id: row[:position].value }])
    end
  end

  def as_json
    {
      comment:           comment,
      executive_item_id: executive_item_id,
      positions:         positions.map(&:as_json)
    }
  end
end
