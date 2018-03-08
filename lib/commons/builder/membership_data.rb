# This class handles the data we have from Wikidata about memberships

class MembershipData

  attr_reader :membership_rows, :language_map, :political_entity_kind

  def initialize(membership_rows, language_map, political_entity_kind)
    @membership_rows = membership_rows
    @language_map = language_map
    @political_entity_kind = political_entity_kind
  end

  def persons
    membership_rows.map do |membership|
      {
        name: membership.name_object('name'),
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
  end

  def party_organizations
    membership_rows.select do |membership|
      membership[:party]
    end.map do |membership|
      {
        name: membership.name_object('party_name'),
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
  end

  def entity_organizations
    membership_rows.map do |membership|
      {
        name: membership.name_object('org'),
        id: membership[:org].value,
        classification: 'branch',
        identifiers: [
          {
            scheme: 'wikidata',
            identifier: membership[:org].value,
          },
        ],
        area_id: membership[:org_jurisdiction]&.value,
      }.tap do |o|
        if political_entity_kind == 'legislative'
          seat_count = membership[:org_seat_count].value
          if seat_count.to_s.empty?
            puts "WARNING: no seat count found for the legislature #{wikidata_labels.item_with_label(membership[:org].value)}"
          end
          o['seat_counts'] = {membership[:role].value => seat_count}
        end
      end
    end.uniq.sort_by { |o| o[:id] }
  end

end
