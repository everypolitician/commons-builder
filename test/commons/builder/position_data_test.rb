# frozen_string_literal: true

require 'test_helper'

class PositionDataTest < Minitest::Test
  def example_response_body
    @example_response_body ||= Pathname.new('test/fixtures/brazil-position-data.srj').read
  end

  def expected_parsed_data
    [
      {
        role_id: 'Q18964326',
        role_name: { 'lang:en': 'Member of the Senate of Brazil' },
        generic_role_id: 'Q15686806',
        generic_role_name: { 'lang:pt': 'senador', 'lang:en': 'senator' },
        role_level: 'Q6256',
        role_type: 'Q4175034',
        organization_id: 'Q2119413',
        organization_name: { 'lang:pt': 'Senado Federal do Brasil',
                             'lang:en': 'Federal Senate of Brazil', },
      },
      { role_id: 'Q24255165',
        role_name: { 'lang:pt': 'Prefeito de São Paulo', 'lang:en': 'Mayor of São Paulo' },
        generic_role_id: 'Q30185',
        generic_role_name: { 'lang:pt': 'prefeito', 'lang:en': 'mayor' },
        role_level: 'Q15284 Q515',
        role_type: nil,
        organization_id: 'Q10351100',
        organization_name: { 'lang:pt': 'Prefeitura do Município de São Paulo',
                             'lang:en': 'municipal prefecture of São Paulo', }, },
    ]
  end

  def test_update
    mock_client = MiniTest::Mock.new
    mock_client.expect(:perform_raw, example_response_body, [String])
    Dir.mktmpdir do |tmpdir|
      tmpdir_pn = Pathname.new(tmpdir)
      position_data = PositionData.new(
        output_dir_pn: tmpdir_pn,
        wikidata_client: mock_client,
        config: Config.new(languages: %w[pt en], country_wikidata_id: 'Q155')
      )
      position_data.update
      assert_equal example_response_body, tmpdir_pn.join('position-data-query-results.json').read
    end
    mock_client.verify
  end

  def test_build
    Dir.mktmpdir do |tmpdir|
      tmpdir_pn = Pathname.new(tmpdir)
      tmpdir_pn.join('position-data-query-results.json').write(example_response_body)
      position_data = PositionData.new(
        output_dir_pn: tmpdir_pn,
        wikidata_client: nil,
        config: Config.new(languages: %w[pt en], country_wikidata_id: 'Q155')
      )
      position_data.build
      assert_equal(
        expected_parsed_data,
        JSON.parse(tmpdir_pn.join('position-data.json').read, symbolize_names: true)
      )
    end
  end
end
