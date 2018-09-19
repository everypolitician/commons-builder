# frozen_string_literal: true

class Legislature < Branch
  KNOWN_PROPERTIES = %i[comment house_item_id position_item_id number_of_seats terms].freeze

  attr_accessor(*(KNOWN_PROPERTIES - [:terms]))

  def output_relative
    Pathname.new(house_item_id)
  end

  def positions_item_ids
    [position_item_id]
  end

  def terms
    @terms.map { |t| LegislativeTerm.new(legislature: self, **t) }
  end

  def self.legislatures_from_wikidata(config, save_queries)
    query = Query.new(
      sparql_query: WikidataQueries.new(config).templated_query('legislative_index'),
      output_dir_pn: Pathname.new('legislative'),
      output_fname_prefix: 'index-'
    )
    WikidataResultsParser.new(languages: config.languages).parse(
      query.run(wikidata_client: WikidataClient.new, save_query_used: save_queries, save_query_results: false)
    )
  end

  def self.terms_from_wikidata(config, save_queries, legislatures)
    query = Query.new(
      sparql_query: WikidataQueries.new(config).templated_query(
        'legislative_index_terms',
        house_positions: legislatures.map do |legislature|
          { 'house'    => legislature[:legislature].value,
            'position' => legislature[:legislaturePost]&.value, }
        end
      ),
      output_dir_pn: Pathname.new('legislative'),
      output_fname_prefix: 'index-terms-'
    )
    WikidataResultsParser.new(languages: config.languages).parse(
      query.run(wikidata_client: WikidataClient.new, save_query_used: save_queries, save_query_results: false)
    )
  end

  def self.terms_or_default(terms)
    if terms.empty?
      [
        {
          start_date: "#{Time.new.year}-01-01",
          end_date:   "#{Time.new.year}-12-31",
        },
      ]
    else
      terms
    end
  end

  def self.list(config, save_queries: false)
    legislatures = legislatures_from_wikidata(config, save_queries)

    term_rows = terms_from_wikidata(config, save_queries, legislatures)

    terms_by_legislature = Hash.new { |h, k| h[k] = [] }

    term_rows.each do |term_row|
      term = {
        term_item_id: term_row[:term].value,
        comment:      term_row[:termLabel].value,
      }
      term[:start_date] = term_row[:termStart].value if term_row[:termStart]
      term[:end_date] = term_row[:termEnd].value if term_row[:termEnd]
      term[:position_item_id] = term_row[:termSpecificPosition].value if term_row[:termSpecificPosition]

      terms_by_legislature[term_row[:house].value]
      terms_by_legislature[term_row[:house].value].push(term)
    end

    # Return the rows as Legislature objects
    legislatures_unsorted = legislatures.map do |l|
      new(comment:          l[:legislatureLabel].value,
          house_item_id:    l[:legislature].value,
          position_item_id: l[:legislaturePost]&.value,
          number_of_seats:  l[:numberOfSeats]&.value,
          terms:            terms_or_default(terms_by_legislature[l[:legislature].value]))
    end

    legislatures_unsorted.sort_by { |h| [h.house_item_id, h.position_item_id] }
  end

  def as_json
    {
      comment:          @comment,
      house_item_id:    @house_item_id,
      position_item_id: @position_item_id,
      number_of_seats:  @number_of_seats,
      terms:            terms.map(&:as_json),
    }
  end
end
