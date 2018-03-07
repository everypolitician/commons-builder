require 'test_helper'
require 'timecop'
require 'webmock/minitest'
require 'commons/builder/legislature'
require 'commons/builder/legislative_term'

class Commons::LegislativeIndexTest < Minitest::Test
  def test_legislative_term_item_as_json
    term = LegislativeTerm.new({legislature: nil, term_item_id: "Q123", comment: "Test term"})
    assert_equal term.as_json, {
      comment:      "Test term",
      term_item_id: "Q123",
    }
  end

  def test_legislative_term_dates_as_json
    term = LegislativeTerm.new({legislature: nil, start_date: "1970-01-01", end_date: "1970-12-31"})
    assert_equal term.as_json, {
      start_date: "1970-01-01",
      end_date:   "1970-12-31",
    }
  end
end
