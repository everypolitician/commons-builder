# frozen_string_literal: true

class Executive < Branch
  KNOWN_PROPERTIES = %i[comment executive_item_id area_id positions].freeze

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

  def self.executives(config, wikidata_client, save_queries)
    wikidata_queries = WikidataQueries.new(config)
    wikidata_results_parser = WikidataResultsParser.new(languages: config.languages)
    query = Query.new(
      sparql_query: wikidata_queries.templated_query('executive_index'),
      output_dir_pn: Pathname.new('executive'),
      output_fname_prefix: 'index-'
    )
    wikidata_results_parser.parse(
      query.run(wikidata_client: wikidata_client, save_query_used: save_queries, save_query_results: false)
    )
  end

  def self.list(config, save_queries: false)
    wikidata_client = WikidataClient.new
    wikidata_labels = WikidataLabels.new(config: config, wikidata_client: wikidata_client)

    executives = executives(config, wikidata_client, save_queries)
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
    executives_sorted = executives.sort_by { |row| row[:executive].value }
    executives_grouped = executives_sorted.group_by do |row|
      [row[:executive].value,
       row[:executiveLabel]&.value,
       row[:adminArea]&.value,]
    end

    executives_grouped.map do |(executive_item_id, comment, area_id), rows|
      new(
        executive_item_id: executive_item_id,
        area_id:           area_id,
        comment:           comment,
        positions:         rows.map do |row|
          { comment:          row[:positionLabel]&.value,
            position_item_id: row[:position].value, }
        end
      )
    end
  end

  def as_json
    {
      comment:           comment,
      area_id:           area_id,
      executive_item_id: executive_item_id,
      positions:         positions.map(&:as_json),
    }
  end
end
