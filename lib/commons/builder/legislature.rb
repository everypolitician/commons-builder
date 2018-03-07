class Legislature < Branch
  KNOWN_PROPERTIES = %i[comment house_item_id position_item_id terms].freeze

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

  def as_json
    {
        comment: @comment,
        house_item_id: @house_item_id,
        position_item_id: @position_item_id,
        terms: terms.map { |t| t.as_json },
    }
  end
end
