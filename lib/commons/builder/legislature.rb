# frozen_string_literal: true

class Legislature < Branch
  KNOWN_PROPERTIES = %i[comment house_item_id position_item_id terms].freeze

  attr_accessor(*(KNOWN_PROPERTIES - [:terms]))

  def output_relative
    Pathname.new(house_item_id)
  end

  def item_id
    house_item_id
  end

  def positions_item_ids
    [position_item_id]
  end

  def terms
    @terms.map { |t| LegislativeTerm.new(legislature: self, **t) }
  end

  def self.list(config, save_queries: false)
    wikidata_queries = WikidataQueries.new(config)
    sparql_query = wikidata_queries.templated_query('legislative_index')

    open('legislative/index-query-used.rq', 'w').write(sparql_query) if save_queries
    legislatures = wikidata_queries.perform(sparql_query)

    # Now collect term information
    sparql_query = wikidata_queries.templated_query(
      'legislative_index_terms',
      houses: legislatures.map { |legislature| legislature[:legislature].value }
    )
    open('legislative/index-terms-query-used.rq', 'w').write(sparql_query) if save_queries
    term_rows = wikidata_queries.perform(sparql_query)

    terms_by_legislature = Hash.new { |h, k| h[k] = [] }

    term_rows.each do |term_row|
      term = {
        term_item_id: term_row[:term].value,
        comment:      term_row[:termLabel].value,
      }
      term[:start_date] = term_row[:termStart].value if term_row[:termStart]
      term[:end_date] = term_row[:termEnd].value if term_row[:termEnd]

      terms_by_legislature[term_row[:house].value]
      terms_by_legislature[term_row[:house].value].push(term)
    end

    this_year_term = {
      start_date: "#{Time.new.year}-01-01",
      end_date:   "#{Time.new.year}-12-31",
    }

    # Return the rows as Legislature objects
    legislatures.map do |l|
      terms = if terms_by_legislature[l[:legislature].value].empty?
                [this_year_term]
              else
                terms_by_legislature[l[:legislature].value]
              end
      new(comment:          l[:legislatureLabel].value,
          house_item_id:    l[:legislature].value,
          position_item_id: l[:legislaturePost]&.value,
          terms:            terms)
    end
  end

  def self.constituencies(config, legislatures)
    wikidata_queries = WikidataQueries.new(config)
    sparql_query = wikidata_queries.templated_query(
      'legislative_constituencies',
      legislatures: legislatures.map(&:house_item_id),
    )
    puts sparql_query
    wikidata_queries.perform(sparql_query)
  end

  def constituencies(config)
    Legislature.constituencies(config, [self])
  end

  def as_json
    {
      comment:          @comment,
      house_item_id:    @house_item_id,
      position_item_id: @position_item_id,
      terms:            terms.map(&:as_json),
    }
  end
end
