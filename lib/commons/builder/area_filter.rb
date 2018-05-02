# frozen_string_literal: true

class AreaIdentityFilter
  def should_include?(_area_feature_data)
    true
  end
end

class AreaMatchFilter
  def initialize(required_match, column)
    @required_match = required_match
    @column = column
  end

  def should_include?(area_feature_data)
    required_match === area_feature_data[column]
  end

  private

  attr_reader :required_match, :column
end

class AreaFilterFactory
  def self.for(filter_data)
    return AreaIdentityFilter.new unless filter_data
    if filter_data[:parent]
      return AreaMatchFilter.new(filter_data[:parent], 'MS_FB_PARE')
    elsif filter_data[:match] && filter_data[:column]
      return AreaMatchFilter.new(Regexp.new(filter_data[:match]), filter_data[:column])
    else
      raise "Unknown filter specification: #{filter_data}"
    end
  end
end
