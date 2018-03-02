require 'test_helper'

class Commons::AreaFilterTest < Minitest::Test

  def test_factory_for_returns_identity_filter_for_nil_param
    filter = AreaFilterFactory.for(nil)
    assert_kind_of(AreaIdentityFilter, filter)
  end

  def test_factory_for_returns_match_filter_for_hash_with_parent_key
    filter = AreaFilterFactory.for(parent: 'xxx')
    assert_kind_of(AreaMatchFilter, filter)
  end

  def test_factory_for_returns_match_filter_for_hash_with_match_and_column_keys
    filter = AreaFilterFactory.for(match: 'xxx', column: 'MS_FB')
    assert_kind_of(AreaMatchFilter, filter)
  end

  def test_factory_for_raises_error_for_hash_with_other_key
    error = assert_raises{ AreaFilterFactory.for(something: 'xxx') }
    expected_message = 'Unknown filter specification: {:something=>"xxx"}'
    assert_equal(expected_message, error.message)
  end

  def test_area_identity_filter_should_include_returns_true
    assert_equal(true, AreaIdentityFilter.new.should_include?({}))
  end

  def test_area_match_filter_returns_false_if_regex_not_matched_in_column
    filter = AreaMatchFilter.new(/xxx/, 'MS_FB')
    assert_equal(false, filter.should_include?('MS_FB' => 'yyy'))
  end

  def test_area_match_filter_returns_false_if_regex_matched_in_other_column
    filter = AreaMatchFilter.new(/xxx/, 'MS_FB')
    assert_equal(false, filter.should_include?('MS_FB_PARE' => 'xxx',
                                               'MS_FB' => 'yyy'))
  end

  def test_area_match_filter_returns_true_if_regex_matched_in_column
    filter = AreaMatchFilter.new(/xxx/, 'MS_FB')
    assert_equal(true, filter.should_include?('MS_FB' => 'xxx'))
  end

  def test_area_match_filter_returns_true_if_string_matched_in_column
    filter = AreaMatchFilter.new('xxx', 'MS_FB')
    assert_equal(true, filter.should_include?('MS_FB' => 'xxx'))
  end

end
