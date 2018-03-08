# This class handles the data we have from Wikidata about memberships

class MembershipData

  attr_reader :membership_rows, :language_map

  def initialize(membership_rows, language_map)
    @membership_rows = membership_rows
    @language_map = language_map
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


end
