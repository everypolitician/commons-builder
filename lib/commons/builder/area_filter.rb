class AreaIdentityFilter
  def should_include?(area_feature_data)
    true
  end
end

class AreaParentFilter
  def initialize(required_parent)
    @required_parent = required_parent
  end

  def should_include?(area_feature_data)
    area_feature_data['MS_FB_PARE'] == required_parent
  end

  private

  attr_reader :required_parent
end

class AreaFilterFactory
  def self.for(filter_data)
    return AreaIdentityFilter.new unless filter_data
    if filter_data[:parent]
      return AreaParentFilter.new(filter_data[:parent])
    else
      raise "Unknown filter specification: #{filter_data}"
    end
  end
end
