require 'test_helper'

class Commons::MembershipDataTest < Minitest::Test

  def membership_rows(pathname)
    data = JSON.parse(File.read(pathname), symbolize_names: true)
    data[:results][:bindings].map do |row|
      WikidataRow.new(row, language_map)
    end
  end

  def json_data(pathname)
    JSON.parse(File.read(pathname), symbolize_names: true)
  end

  def language_map
    { "lang:en_US": "en",
      "lang:zh_TW": "zh-tw",
      "lang:zh_CN": "zh" }
  end

  def test_can_access_membership_rows
    membership_rows = []
    membership_data = MembershipData.new(membership_rows, language_map, 'executive')
    assert_equal(membership_rows, membership_data.membership_rows)
  end

  def test_persons_produces_expected_json
    membership_rows = membership_rows('test/fixtures/membership_data/results.json')
    membership_data = MembershipData.new(membership_rows, language_map, 'executive')
    expected_data = json_data('test/fixtures/membership_data/expected.json')
    assert_equal(expected_data[:persons], membership_data.persons)
  end

  def test_memberships_produces_expected_json
    membership_rows = membership_rows('test/fixtures/membership_data/results.json')
    membership_data = MembershipData.new(membership_rows, language_map, 'executive')
    expected_data = json_data('test/fixtures/membership_data/expected.json')
    assert_equal(expected_data[:memberships], membership_data.memberships)
  end

  def test_organizations_produces_expected_json
    membership_rows = membership_rows('test/fixtures/membership_data/results.json')
    membership_data = MembershipData.new(membership_rows, language_map, 'executive')
    expected_data = json_data('test/fixtures/membership_data/expected.json')
    assert_equal(expected_data[:organizations], membership_data.organizations)
  end

  def test_persons_assigns_multiple_links
    membership_rows = membership_rows('test/fixtures/two_links/results.json')
    membership_data = MembershipData.new(membership_rows, language_map, 'executive')
    expected_data = json_data('test/fixtures/two_links/expected.json')
    assert_equal(expected_data[:organizations], membership_data.organizations)
  end

end