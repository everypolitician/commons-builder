# frozen_string_literal: true

class CurrentExecutive
  def initialize(executive:)
    @executive = executive
  end

  attr_accessor :executive

  def query(config)
    WikidataQueries.new(config).templated_query('executive',
                                                executive_item_id: executive.executive_item_id,
                                                position_item_ids: executive.positions.map(&:position_item_id),
                                                current: true)
  end

  def output_relative
    executive.output_relative.join('current')
  end
end
