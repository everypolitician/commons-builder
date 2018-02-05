# frozen_string_literal: true

require 'json'
require 'pathname'

CONFIG = JSON.parse(
  Pathname.new('config.json').read,
  symbolize_names: true
)
