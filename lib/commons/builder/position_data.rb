# frozen_string_literal: true

class PositionData
  def initialize(output_dir_pn:, wikidata_client:, config:)
    @output_dir_pn = output_dir_pn
    @wikidata_client = wikidata_client
    @config = config
  end

  def update
    query.run(wikidata_client: wikidata_client)
  end

  def build
    position_data = parsed_data.map do |wd_row|
      {
        role_id: wd_row[:position].value,
        role_name: wd_row.name_object('position_name'),
        generic_role_id: wd_row[:positionSuperclass].value,
        generic_role_name: wd_row.name_object('position_superclass'),
        role_level: wd_row[:adminAreaTypes].value,
        role_type: wd_row[:positionType]&.value,
        organization_id: wd_row[:body].value,
        organization_name: wd_row.name_object('body'),
      }
    end
    # There might be multiple generic_roles (e.g. President of Brazil is
    # sublassed both from 'head of government' and 'president') but we
    # don't need both. Sort predictably but arbitrarily and pick the
    # first of those:
    deduplicated = position_data.group_by { |e| e[:role_id] }.values.map do |roles|
      roles.sort_by { |r| r[:generic_role_id] }[0]
    end
    # Now write it to disk:
    output_dir_pn.join('position-data.json').write(
      JSON.pretty_generate(deduplicated) + "\n"
    )
  end

  private

  attr_reader :output_dir_pn, :wikidata_client, :config

  def parser
    WikidataResultsParser.new(languages: config.languages)
  end

  def parsed_data
    parser.parse(query.query_results_pn.read)
  end

  def sparql_query
    @sparql_query ||= WikidataQueries.new(config).templated_query('information_from_positions')
  end

  def query
    @query ||= Query.new(
      sparql_query: sparql_query,
      output_dir_pn: output_dir_pn,
      output_fname_prefix: 'position-data-'
    )
  end
end
