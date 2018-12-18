# frozen_string_literal: true

# This class handles the data we have from Wikidata about memberships

class MembershipData
  attr_reader :membership_rows, :wikidata_labels, :political_entity_kind, :term

  def initialize(membership_rows, wikidata_labels, political_entity_kind, term, options = {})
    @membership_rows = membership_rows
    @wikidata_labels = wikidata_labels
    @political_entity_kind = political_entity_kind
    @output_stream = options.fetch(:output_stream) { $stdout }
    @term = term
  end

  def persons
    persons = {}
    membership_rows.each do |membership|
      person_id = membership[:item].value
      persons[person_id] = person(membership) unless persons[person_id]
      link = link(membership)
      persons[person_id][:links] << link if link
    end
    persons.each_value { |p| p[:links].uniq! }
    persons.values.sort_by { |p| p[:id] }
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

  def organizations
    party_organizations
  end

  def memberships
    membership_rows.map do |membership|
      {
        id: membership[:statement].value,
        person_id: membership[:item].value,
        on_behalf_of_id: membership[:party]&.value,
        organization_id: membership[:org].value,
        area_id: membership[:district]&.value,
        start_date: membership[:start]&.value,
        end_date: membership[:end]&.value,
        role_superclass_code: membership[:role_superclass]&.value,
        role_superclass: membership[:role_superclass] && membership.name_object('role_superclass'),
        role_code: membership[:role].value,
        role: membership.name_object('role'),
        term_id: (membership[:linkedToTerm]&.value ? term.term_item_id : nil),
      }.reject { |_, v| v.to_s.empty? }
      # The id here is the statement UUID, so you would have thought
      # that was enough to predictably order these, However, the
      # on_behalf_of_id might be from a P102 on the *person* so we
      # need to add that too.
    end.uniq.sort_by { |m| [m[:id], m[:on_behalf_of_id]] }
  end

  private

  def person(membership)
    {
      name: membership.name_object('name'),
      id: membership[:item].value,
      identifiers: [
        {
          scheme: 'wikidata',
          identifier: membership[:item].value,
        },
      ],
      links: [],
    }
  end

  def link(membership)
    url = membership[:facebook]&.value&.prepend('https://www.facebook.com/')
    return unless url
    {
      note: 'facebook',
      url: url,
    }
  end
end
