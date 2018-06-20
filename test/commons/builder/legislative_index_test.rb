# frozen_string_literal: true

require 'test_helper'
require 'timecop'
require 'webmock/minitest'
require 'commons/builder/legislature'
require 'commons/builder/legislative_term'

module Commons
  class LegislativeIndexTest < Minitest::Test
    def config(languages: ['en'])
      data = { 'languages': languages, 'country_wikidata_id': 'Q16' }
      Config.new(data)
    end

    def test_legislative_term_item_as_json
      term = LegislativeTerm.new legislature: nil, term_item_id: 'Q123', comment: 'Test term'
      expected = {
        comment:      'Test term',
        term_item_id: 'Q123',
      }
      assert_equal expected, term.as_json
    end

    def test_legislative_term_dates_as_json
      term = LegislativeTerm.new legislature: nil, start_date: '1970-01-01', end_date: '1970-12-31'
      expected = {
        start_date: '1970-01-01',
        end_date:   '1970-12-31',
      }
      assert_equal expected, term.as_json
    end

    def test_legislative_term_with_position_as_json
      term = LegislativeTerm.new legislature: nil, term_item_id: 'Q123', comment: 'Test term', position_item_id: 'Q456'
      expected = {
        comment:          'Test term',
        term_item_id:     'Q123',
        position_item_id: 'Q456',
      }
      assert_equal expected, term.as_json
    end

    def test_legislature_as_json
      term = { comment: 'Term', term_item_id: 'Q3' }
      legislature = Legislature.new terms: [term], house_item_id: 'Q1',
                                    position_item_id: 'Q2', comment: 'Test legislature'
      expected = {
        comment:          'Test legislature',
        house_item_id:    'Q1',
        position_item_id: 'Q2',
        terms: [
          {
            comment:      'Term',
            term_item_id: 'Q3',
          },
        ],
      }
      assert_equal expected, legislature.as_json
    end

    def test_legislature_list
      stub_request(:post, 'https://query.wikidata.org/sparql')
        .to_return(body: open('test/fixtures/legislative-index.srj', 'r')).then
        .to_return(body: open('test/fixtures/legislative-index-terms.srj', 'r'))

      Timecop.freeze(Date.new(2010, 0o1, 0o1)) do
        legislatures = Legislature.list(config)
        assert_equal 'Senate of Canada', legislatures[0].comment
        assert_equal LegislativeTerm.new(legislature: legislatures[0],
                                         term_item_id: 'Q21157957',
                                         start_date: '2015-12-03',
                                         comment: '42nd Canadian Parliament',
                                         position_item_id: 'Q30524710'), legislatures[0].terms[0]

        # This one has no term in the fixture data
        assert_equal 'Calgary City Council', legislatures[2].comment
        assert_equal LegislativeTerm.new(legislature: legislatures[2],
                                         start_date: '2010-01-01',
                                         end_date: '2010-12-31'), legislatures[2].terms[0]
      end
    end
  end
end
