require 'json'
require 'pathname'

CONFIG = JSON.parse(
  Pathname.new(__FILE__).dirname.join('..').join('config.json').read,
  symbolize_names: true
)
