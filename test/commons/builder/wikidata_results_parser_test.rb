# frozen_string_literal: true

require 'test_helper'

module Commons
  class WikidataResultsParserTest < Minitest::Test
    def parser
      WikidataResultsParser.new(languages: %w[en fr])
    end

    def test_can_parse_a_simple_response
      response = <<~RESPONSE
        {
          "head": {
            "vars": [
              "name_en",
              "name_fr"
            ]
          },
          "results": {
            "bindings": [
              {
                "name_fr": {
                  "type": "literal",
                  "value": "Ontario",
                  "xml:lang": "fr"
                },
                "name_en": {
                  "type": "literal",
                  "value": "Ontario",
                  "xml:lang": "en"
                }
              }
            ]
          }
        }
      RESPONSE
      parsed = parser.parse(response)
      assert_equal(1, parsed.length)
      assert_equal(
        parsed[0].name_object('name'),
        'lang:en': 'Ontario',
        'lang:fr': 'Ontario'
      )
    end
  end
end
