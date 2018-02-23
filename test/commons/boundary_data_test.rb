require 'test_helper'

class Commons::BoundaryDataTest < Minitest::Test

  def test_accepts_boundaries_dir
    options = { boundaries_dir: 'test/fixtures/boundaries_init' }
    boundary_data = BoundaryData.new(nil, options)
    assert_equal('test/fixtures/boundaries_init', boundary_data.boundaries_dir_path)
  end

  def test_default_boundaries_dir
    boundary_data = BoundaryData.new(nil)
    assert_equal('boundaries', boundary_data.boundaries_dir_path)
  end

  def test_accepts_index_file
    options = { index_file: 'test.json' }
    boundary_data = BoundaryData.new(nil, options)
    assert_equal('test.json', boundary_data.index_file)
  end

  def test_default_index_file
    boundary_data = BoundaryData.new(nil)
    assert_equal('index.json', boundary_data.index_file)
  end

  def test_accepts_output
    output_stream = StringIO.new
    options = { output_stream: output_stream }
    boundary_data = BoundaryData.new(nil, options)
    assert_equal(output_stream, boundary_data.output_stream)
  end

  def test_default_output
    boundary_data = BoundaryData.new(nil)
    assert_equal($stdout, boundary_data.output_stream)
  end

  def test_popolo_areas_warns_on_boundaries_without_area_type_wikidata_item_id
    output_stream = StringIO.new
    expected = <<-EOF
WARNING: No :area_type_wikidata_item_id entry for boundary boundaries
EOF
    options = { boundaries_dir: 'test/fixtures/entry_without_area_type_wikidata_item',
                output_stream: output_stream }
    boundary_data = BoundaryData.new(nil, options)
    boundary_data.popolo_areas
    assert_equal(expected, output_stream.string)
  end

end
