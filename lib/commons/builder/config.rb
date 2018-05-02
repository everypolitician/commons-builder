# frozen_string_literal: true

require 'json'
require 'pathname'

class Config
  attr_reader :values

  def initialize(file)
    @values = JSON.parse(
      Pathname.new(file).read,
      symbolize_names: true
    )
  end
end
