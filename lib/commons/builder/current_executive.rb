# frozen_string_literal: true

class CurrentExecutive
  def initialize(executive:)
    @executive = executive
  end

  attr_accessor :executive

  def query(languages)
    WikidataQueries.new(languages).templated_query('executive',
                                                   executive_item_id: executive.executive_item_id,
                                                   positions: executive.positions.map(&:position_item_id))
  end

  def output_relative
    executive.output_relative.join('current')
  end
end
