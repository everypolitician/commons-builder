# frozen_string_literal: true

require 'test_helper'

module Commons
  class BuilderTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Commons::Builder::VERSION
    end
  end
end
