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
      end_date: end_date,
    )
  end

  def output_relative
    if term_item_id
      legislature.output_relative.join(term_item_id)
    else
      legislature.output_relative.join("#{start_date}-to-#{end_date}")
    end
  end
end
