require 'test_helper'

class Commons::BuilderTest < Minitest::Test

  def test_accepts_boundaries_dir
    options = { boundaries_dir: 'test/fixtures/boundaries_init' }
    boundary_data = BoundaryData.new(WikidataLabels.new, options)
    assert_equal('test/fixtures/boundaries_init', boundary_data.boundaries_dir_path)
  end

  def test_default_boundaries_dir
    boundary_data = BoundaryData.new(WikidataLabels.new)
    assert_equal('boundaries', boundary_data.boundaries_dir_path)
  end

  def test_accepts_index_file
    options = { index_file: 'test.json' }
    boundary_data = BoundaryData.new(WikidataLabels.new, options)
    assert_equal('test.json', boundary_data.index_file)
  end

  def test_default_index_file
    boundary_data = BoundaryData.new(WikidataLabels.new)
    assert_equal('index.json', boundary_data.index_file)
  end

end
