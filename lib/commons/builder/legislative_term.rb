# frozen_string_literal: true

class LegislativeTerm
  def initialize(legislature:, term_item_id: nil, start_date: nil, end_date: nil, comment: nil)
    @legislature = legislature
    @term_item_id = term_item_id
    @start_date = start_date
    @end_date = end_date
    @comment = comment
  end

  attr_accessor :legislature, :term_item_id, :start_date, :end_date, :comment

  def query(language_map)
    WikidataQueries.new(language_map).query_legislative(
      position_item_id: legislature.position_item_id,
      house_item_id: legislature.house_item_id,
      term_item_id: term_item_id,
      start_date: start_date,
      end_date: end_date
    )
  end

  def output_relative
    if term_item_id
      legislature.output_relative.join(term_item_id)
    else
      legislature.output_relative.join("#{start_date}-to-#{end_date}")
    end
  end

  def ==(other)
    other.instance_of?(self.class) &&
      legislature == other.legislature &&
      term_item_id == other.term_item_id &&
      start_date == other.start_date &&
      end_date == other.end_date &&
      comment == other.comment
  end

  def as_json
    result = {}
    result[:comment] = @comment if @comment
    if @term_item_id
      result[:term_item_id] = @term_item_id if @term_item_id
    else
      result[:start_date] = @start_date
      result[:end_date] = @end_date
    end
    result
  end
end
