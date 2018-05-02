# frozen_string_literal: true

class CurrentExecutive
  def initialize(executive:)
    @executive = executive
  end

  attr_accessor :executive

  def query(languages)
    WikidataQueries.new(languages).query_executive(
      executive_item_id: executive.executive_item_id,
      positions: executive.positions
    )
  end

  def output_relative
    executive.output_relative.join('current')
  end
end
