class Executive < Branch
  KNOWN_PROPERTIES = %i[comment executive_item_id positions].freeze

  attr_accessor(*KNOWN_PROPERTIES)

  def output_relative
    Pathname.new(executive_item_id)
  end

  def positions_item_ids
    positions.map { |p| p[:position_item_id] }
  end

  def terms
    # We only actually consider current executive positions, but treat
    # this as a "term".
    [CurrentExecutive.new(executive: self)]
  end
end
