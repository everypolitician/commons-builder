require 'test_helper'

class Commons::AreaFilterTest < Minitest::Test

  def test_factory_for_returns_identity_filter_for_nil_param
    filter = AreaFilterFactory.for(nil)
    assert_kind_of(AreaIdentityFilter, filter)
  end

  def test_factory_for_returns_parent_filter_for_hash_with_parent_key
    filter = AreaFilterFactory.for(parent: 'xxx')
    assert_kind_of(AreaParentFilter, filter)
  end

  def test_factory_for_raises_error_for_hash_with_other_key
    error = assert_raises{ AreaFilterFactory.for(something: 'xxx') }
    expected_message = 'Unknown filter specification: {:something=>"xxx"}'
    assert_equal(expected_message, error.message)
  end

  def test_area_identity_filter_should_include_returns_true
    assert_equal(true, AreaIdentityFilter.new.should_include?({}))
  end

  def test_area_parent_filter_returns_false_if_parent_is_not_matched
    filter = AreaParentFilter.new('xxx')
    assert_equal(false, filter.should_include?('MS_FB_PARE' => 'yyy'))
  end

  def test_area_parent_filter_returns_true_if_parent_matched
    filter = AreaParentFilter.new('xxx')
    assert_equal(false, filter.should_include?('MS_FB_PARE': 'xxx'))
  end

end
