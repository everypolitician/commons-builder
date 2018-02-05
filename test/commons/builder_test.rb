require "test_helper"

class Commons::BuilderTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Commons::Builder::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
