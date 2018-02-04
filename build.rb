# frozen_string_literal: true

require 'rest-client'
require 'json'

require_relative 'lib/results'
require_relative 'lib/labels'
require_relative 'lib/boundary_data'
require_relative 'lib/config'
require_relative 'lib/queries'

URL = 'https://query.wikidata.org/sparql'

LANGUAGE_MAP = CONFIG[:language_map]
COUNTRY_WIKIDATA_ID = CONFIG[:country_wikidata_id]

root_dir = Pathname.new(__FILE__).dirname

valid_actions = %w(update build)

unknown_args = Set.new(ARGV) - Set.new(valid_actions)
if unknown_args.length > 0
  STDERR.puts "Usage: #{$0} update|build"
  exit(1)
end

if ARGV.empty?
  actions = valid_actions.clone
else
  actions = ARGV.clone
end

wikidata_labels = WikidataLabels.new
boundary_data = BoundaryData.new(wikidata_labels)

class Branch
  def initialize(**properties)
    self.class::KNOWN_PROPERTIES.each do |p|
      self.class.send(:attr_accessor, p)
      self.send("#{p}=", properties.delete(p))
    end
    raise "Unknown properties: #{properties}" unless properties.empty?
  end

  def self.for(type, properties)
    {
      'legislative' => Legislature,
      'executive' => Executive
    }.fetch(type).new(**properties)
  end
end

class Legislature < Branch
  KNOWN_PROPERTIES = %i(comment house_item_id position_item_id term_item_id start_date end_date)

  def output_relative
    house_item_id
  end

  def query
    query_legislative(
      position_item_id: position_item_id,
      house_item_id: house_item_id,
      term_item_id: term_item_id,
      start_date: start_date,
      end_date: end_date,
    )
  end

  def positions_item_ids
    [position_item_id]
  end
end

class Executive < Branch
  KNOWN_PROPERTIES = %i(comment executive_item_id positions)

  def output_relative
    executive_item_id
  end

  def query
    query_executive(
      executive_item_id: executive_item_id,
      positions: positions,
    )
  end

  def positions_item_ids
    positions.map { |p| p[:position_item_id] }
  end
end

['legislative', 'executive'].each do |political_entity_kind|
  political_entity_kind_dir = root_dir.join(political_entity_kind)
  index_file = political_entity_kind_dir.join('index.json')

  JSON.parse(index_file.read, symbolize_names: true).each do |political_entity_h|
    branch = Branch.for(political_entity_kind, political_entity_h)
    output_dir = political_entity_kind_dir.join(branch.output_relative)
    output_dir.mkpath
    output_pathname = output_dir.join('popolo-m17n.json')
    raw_results_pathname = output_dir.join('query-results.json')

    if actions.include? 'update'
      sparql_query = branch.query
      output_dir.join('query-used.rq').write(sparql_query)

      query_params = {
        query: sparql_query,
        format: 'json',
      }
      result = RestClient.get(URL, params: query_params)

      raw_results_pathname.write(result)
    end

    if actions.include?('build')
      data = JSON.parse(raw_results_pathname.read(), symbolize_names: true)

      membership_rows = data[:results][:bindings].map do |row|
        Row.new(row)
      end

      persons = membership_rows.map do |membership|
        {
          name: membership.name_object('name', LANGUAGE_MAP),
          id: membership[:item].value,
          identifiers: [
            {
              scheme: 'wikidata',
              identifier: membership[:item].value,
            },
          ],
          links: [
            {
              note: 'facebook',
              url: membership[:facebook]&.value&.prepend('https://www.facebook.com/'),
            },
          ].select { |o| o[:url] },
        }
      end.uniq.sort_by { |p| p[:id] }

      party_organizations = membership_rows.select do |membership|
        membership[:party]
      end.map do |membership|
        {
          name: membership.name_object('party_name', LANGUAGE_MAP),
          id: membership[:party].value,
          classification: 'party',
          identifiers: [
            {
              scheme: 'wikidata',
              identifier: membership[:party].value,
            },
          ],
        }
      end.uniq.sort_by { |o| o[:id] }

      entity_organizations = membership_rows.map do |membership|
        {
          name: membership.name_object('org', LANGUAGE_MAP),
          id: membership[:org].value,
          classification: 'branch',
          identifiers: [
            {
              scheme: 'wikidata',
              identifier: membership[:org].value,
            }
          ],
          area_id: membership[:org_jurisdiction]&.value,
        }
      end.uniq.sort_by { |o| o[:id] }

      missing_jurisdictions = entity_organizations.reject { |o| o[:area_id] }
      missing_jurisdictions.each do |o|
        puts "ERROR: no P1001 (applies to jurisdiction) on #{political_entity_kind} #{wikidata_labels.item_with_label(o[:id])}"
      end
      exit(1) unless missing_jurisdictions.empty?

      # We should have all the relevant areas from the boundary data...
      related_positions = branch.positions_item_ids
      areas = boundary_data.popolo_areas.reject do |a|
        (a[:associated_wikidata_positions] & related_positions).empty?
      end.uniq.sort_by { |a| a[:id] }
      # ... but warn about any districts found from Wikidata that aren't
      # in that set:
      known_areas = Set.new(areas.map { |a| a[:id] })
      membership_rows.select { |m| m[:district] }.map do |m|
        area_wikidata_id = m[:district].value
        unless known_areas.include?(area_wikidata_id)
          puts "WARNING: the district #{wikidata_labels.item_with_label(area_wikidata_id)} wasn't found in the boundary data for position #{wikidata_labels.item_with_label(m[:role]&.value)}"
        end
      end

      # Check that none of these have a null person_id - we should only
      # allow that for the whole-country area.
      areas_with_bad_parents = areas.select do |area|
        area[:parent_id].nil? && ! area[:id] == COUNTRY_WIKIDATA_ID
      end
      unless areas_with_bad_parents.empty?
        areas_with_bad_parents.each do |area|
          puts "Error: no parent area found for: #{area[:id]}"
        end
        raise "Some areas has a null parent_id"
      end

      area_country = boundary_data.popolo_areas.find { |a| a[:id] == COUNTRY_WIKIDATA_ID }

      memberships = membership_rows.map do |membership|
        {
          id: membership[:statement].value,
          person_id: membership[:item].value,
          on_behalf_of_id: membership[:party]&.value,
          organization_id: membership[:org].value,
          area_id: membership[:district]&.value,
          start_date: membership[:start]&.value,
          end_date: membership[:end]&.value,
          role_superclass_code: membership[:role_superclass]&.value,
          role_superclass: membership[:role_superclass] && membership.name_object('role_superclass', LANGUAGE_MAP),
          role_code: membership[:role].value,
          role: membership.name_object('role', LANGUAGE_MAP),
        }.reject { |_, v| v.to_s.empty? }
      end.uniq.sort_by { |m| m[:id] }

      all_data = {
        persons: persons,
        organizations: entity_organizations + party_organizations,
        areas: [area_country] + areas,
        memberships: memberships,
      }

      output_pathname.write(JSON.pretty_generate(all_data) + "\n")
    end
  end
end
