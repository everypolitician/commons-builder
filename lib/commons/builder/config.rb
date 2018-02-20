# frozen_string_literal: true

require 'json'
require 'pathname'


class Config

  def initialize(file)
    @config = JSON.parse(
      Pathname.new(file).read,
      symbolize_names: true
    )
  end

end
