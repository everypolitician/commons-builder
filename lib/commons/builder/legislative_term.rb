# frozen_string_literal: true

class LegislativeTerm
  def initialize(legislature:, term_item_id: nil, position_item_id: nil,
                 start_date: nil, end_date: nil, **extra)
    raise 'You must specify a term item or a start and end date' if !term_item_id && !(start_date and end_date)
    @legislature = legislature
    @position_item_id = position_item_id
    @term_item_id = term_item_id
    @start_date = start_date
    @end_date = end_date
    @extra = extra
  end

  attr_accessor :legislature, :term_item_id, :position_item_id, :start_date, :end_date, :extra

  def query(config)
    WikidataQueries.new(config).templated_query('legislative',
                                                position_item_id: legislature.position_item_id,
                                                specific_position_item_id: specific_position_item_id,
                                                house_item_id: legislature.house_item_id,
                                                term_item_id: term_item_id,
                                                start_date: start_date,
                                                end_date: end_date)
  end

  def specific_position_item_id
    position_item_id || legislature.position_item_id
  end

  def output_relative
    if term_item_id
      legislature.output_relative.join(term_item_id)
    else
      legislature.output_relative.join("#{start_date}-to-#{end_date}")
    end
  end

  def ==(other)
    false unless other.instance_of? self.class
    %i[legislature term_item_id start_date end_date extra position_item_id].all? do |name|
      send(name) == other.send(name)
    end
  end

  def as_json
    result = extra.clone
    result[:position_item_id] = @position_item_id if @position_item_id
    if @term_item_id
      result[:term_item_id] = @term_item_id if @term_item_id
    else
      result[:start_date] = @start_date
      result[:end_date] = @end_date
    end
    result
  end
end
