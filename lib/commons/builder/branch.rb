# frozen_string_literal: true

class Branch
  def initialize(**properties)
    self.class::KNOWN_PROPERTIES.each do |p|
      instance_variable_set("@#{p}", properties.delete(p))
    end
    raise "Unknown properties: #{properties}" unless properties.empty?
  end

  def self.branch_types
    {
        'legislative' => Legislature,
        'executive' => Executive,
    }
  end

  def self.for(type, properties)
    branch_types.fetch(type).new(**properties)
  end
end
