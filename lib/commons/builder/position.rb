# frozen_string_literal: true

class Position
  attr_accessor :branch, :comment, :position_item_id

  def initialize(branch:, comment:, position_item_id:)
    @branch = branch
    @comment = comment
    @position_item_id = position_item_id
  end

  def as_json
    {
      comment:          comment,
      position_item_id: position_item_id,
    }
  end

  def ==(other)
    other.instance_of?(self.class) && \
      branch == other.branch && \
      comment == other.comment && \
      position_item_id == other.position_item_id
  end
end
