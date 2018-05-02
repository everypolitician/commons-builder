# frozen_string_literal: true

class WikidataQueries < Wikidata
  def date_condition(start_date, end_date)
    return '' unless start_date
    end_date ||= '9999-12-31'
    <<~DATE_CONDITION
      BIND(COALESCE(?start, "1000-01-01T00:00:00Z"^^xsd:dateTime) AS ?start_or_sentinel)
      BIND(COALESCE(?end, "9999-12-31T00:00:00Z"^^xsd:dateTime) AS ?end_or_sentinel)
      FILTER (?end_or_sentinel >= "#{start_date}"^^xsd:dateTime)
      FILTER (?start_or_sentinel <= "#{end_date}"^^xsd:dateTime)
  DATE_CONDITION
  end

  def term_condition(term_item_id)
    return '' unless term_item_id
    "?statement pq:P2937 wd:#{term_item_id} ."
  end

  # Use this to generate a `SERVICE wikibase:label` SPARQL pattern, for use in
  # situations where you want a single label to help the humans that maintain
  # a democratic commons repository. Do not use it for labels to be presented
  # to end-users, as that needs potentially multiple language-tagged labels.
  # For that, use `lang_select` and `lang_options`.
  def label_service
    languages_with_en = (['en'] + languages).uniq
    "SERVICE wikibase:label { bd:serviceParam wikibase:language \"#{languages_with_en.join(',')}\". }"
  end

  def query_legislative(position_item_id:, house_item_id:, term_item_id: nil, start_date: nil, end_date: nil, **_rest)
    unless !!term_item_id ^ !!(start_date and end_date)
      raise 'You must specify either a term item or a start and end date (and not both)'
    end
    <<~SPARQL
      SELECT ?statement
             ?item #{lang_select}
             ?party #{lang_select('party_name')}
             ?district #{lang_select('district_name')}
             ?role #{lang_select('role')}
             ?role_superclass #{lang_select('role_superclass')}
             ?start ?end ?facebook
             ?org #{lang_select('org')} ?org_jurisdiction ?org_seat_count
      WHERE {
        BIND(wd:#{position_item_id} as ?role) .
        BIND(wd:#{house_item_id} as ?org) .
        #{lang_options('org', '?org')}
        OPTIONAL {
          ?org wdt:P1001 ?org_jurisdiction
        }
        OPTIONAL {
          ?org wdt:P1342 ?org_seat_count
        }
        ?item p:P39 ?statement .
        #{lang_options}
        ?statement ps:P39 ?role .
        #{lang_options('role', '?role')}
        OPTIONAL {
          ?role wdt:P279 ?role_superclass .
          ?role_superclass wdt:P279+ wd:Q4175034
          #{lang_options('role_superclass', '?role_superclass')}
        }
        #{term_condition(term_item_id)}
        OPTIONAL { ?statement pq:P580 ?start }
        OPTIONAL { ?statement pq:P582 ?end }
        OPTIONAL {
          ?statement pq:P768 ?district.
          #{lang_options('district_name', '?district')}
        }
        OPTIONAL {
          ?statement pq:P4100 ?party.
          #{lang_options('party_name', '?party')}
        }
        OPTIONAL { ?item wdt:P2013 ?facebook }
        #{date_condition(start_date, end_date)}
      } ORDER BY ?item ?role #{term_item_id ? '?term ' : ''}?start ?end
  SPARQL
  end

  def query_executive(executive_item_id:, positions:, **_rest)
    space_separated_role_superclass = positions.map { |p| "wd:#{p.position_item_id}" }.join(' ')
    <<~SPARQL
      SELECT ?statement
             ?item #{lang_select}
             ?party #{lang_select('party_name')}
             ?district #{lang_select('district_name')}
             ?role #{lang_select('role')}
             ?start ?end ?facebook
             ?role_superclass #{lang_select('role_superclass')}
             ?org #{lang_select('org')} ?org_jurisdiction
      WHERE {
        VALUES ?role_superclass { #{space_separated_role_superclass} }
        BIND(wd:#{executive_item_id} AS ?org)
        #{lang_options('org', '?org')}
        OPTIONAL {
          ?org wdt:P1001 ?org_jurisdiction
        }
        ?item p:P39 ?statement .
        #{lang_options}
        ?statement ps:P39 ?role .
        #{lang_options('role', '?role')}
        ?role wdt:P279* ?role_superclass .
        #{lang_options('role_superclass', '?role_superclass')}
        ?role wdt:P361 ?org .
        OPTIONAL {
          ?role p:P1001/ps:P1001 ?district .
          #{lang_options('district_name', '?district')}
        }
        OPTIONAL { ?statement pq:P580 ?start }
        OPTIONAL { ?statement pq:P582 ?end }
        BIND(COALESCE(?end, "9999-12-31T00:00:00Z"^^xsd:dateTime) AS ?end_or_sentinel)
        FILTER(?end_or_sentinel >= NOW())
        # Find any current party membership:
        OPTIONAL {
          ?item p:P102 ?party_statement .
          ?party_statement ps:P102 ?party .
          #{lang_options('party_name', '?party')}
          OPTIONAL { ?party_statement pq:P582 ?end_party }
          BIND(COALESCE(?end_party, "9999-12-31T00:00:00Z"^^xsd:dateTime) AS ?party_end_or_sentinel)
          FILTER(?party_end_or_sentinel >= NOW())
        }
        OPTIONAL { ?item wdt:P2013 ?facebook }
      } ORDER BY ?item ?role ?district ?start ?end
  SPARQL
  end

  def select_admin_areas_for_country(country)
    <<~SPARQL
      SELECT DISTINCT ?primarySort ?adminArea ?adminAreaType {
        {
          VALUES (?adminArea ?primarySort ?adminAreaType) { (#{country} 1 wd:Q6256) }
        } UNION {
          # Find FLACSen of this country
          ?adminArea wdt:P17 #{country} ;
                wdt:P31/wdt:P279* wd:Q10864048
          VALUES (?primarySort ?adminAreaType) { (2 wd:Q10864048) }
        } UNION {
          # Find cities with populations of over 250k
          ?adminArea wdt:P17 #{country} ;
             wdt:P31/wdt:P279* wd:Q515 ;
             wdt:P1082 ?population .
          FILTER (?population > 250000)
          # Make sure the city is not also a FLACS
          FILTER NOT EXISTS { ?adminArea wdt:P31/wdt:P279* wd:Q10864048 }
          VALUES (?primarySort ?adminAreaType) { (3 wd:Q515) }
        }
      } ORDER BY ?primarySort
    SPARQL
  end

  def query_legislative_index(country)
    country = "wd:#{country}" unless country.start_with?('wd:')
    <<~SPARQL
      SELECT DISTINCT ?legislature ?legislatureLabel ?country ?countryLabel ?adminArea ?adminAreaLabel ?adminAreaType ?adminAreaTypeLabel ?legislaturePost ?legislaturePostLabel ?numberOfSeats WHERE {
        {
          #{select_admin_areas_for_country(country)}
        }

        ?adminArea wdt:P194/wdt:P527? ?legislature .

        VALUES ?legislatureType { wd:Q11204 wd:Q10553309 }
        ?legislature wdt:P31/wdt:P279* ?legislatureType .
        FILTER (?legislatureType != wd:Q11204 || NOT EXISTS { ?legislature wdt:P527 ?legislaturePart . ?legislaturePart  wdt:P31/wdt:P279* wd:Q10553309 })

        # Attempt to find the position for members of the legislature
        OPTIONAL {
          # Both "has part" and "has parts of class" seem to be used; with the latter not in keeping with the draft model
          ?legislature wdt:P527|wdt:P2670 ?legislaturePost .
          ?legislaturePost wdt:P31/wdt:P279* wd:Q4164871 .
          # Make sure positions are either legislators or councillors (and so exclude e.g. mayors)
          FILTER EXISTS {
            VALUES ?legislaturePostSuperType { wd:Q4175034 wd:Q708492 }
            ?legislaturePost wdt:P279+ ?legislaturePostSuperType .
          }
        }
        OPTIONAL {
          ?legislature wdt:P1342 ?numberOfSeats .
        }

        # Remove legislatures that have ended
        FILTER NOT EXISTS { ?legislature wdt:P576 ?legislatureEnd . FILTER (?legislatureEnd < NOW()) }
        #{label_service}
      } ORDER BY ?primarySort ?country ?adminAreaType ?legislature ?legislaturePost
    SPARQL
  end

  def query_legislative_index_terms(*houses)
    houses = houses.map { |house| "wd:#{house}" }.join(' ')
    <<~SPARQL
      SELECT DISTINCT ?house ?houseLabel ?legislature ?legislatureLabel ?term ?termLabel ?termStart ?termEnd WHERE {
        VALUES ?house { #{houses} }
        ?house (p:P361/ps:P361)* ?legislature .
            ?baseTerm p:P31|p:P279 [ ps:P279|ps:P31 wd:Q15238777 ; pq:P642 ?legislature ] .
            OPTIONAL { ?subTerm wdt:P31 ?baseTerm }

        BIND(COALESCE(?subTerm, ?baseTerm) AS ?term)

        OPTIONAL { ?term (wdt:P580|wdt:P571) ?termStart. }
        OPTIONAL { ?term (wdt:P582|wdt:P576) ?termEnd. }
        OPTIONAL { ?term (wdt:P155|wdt:P1365) ?termReplaces }
        OPTIONAL { ?term (wdt:P156|wdt:P1366) ?termReplacedBy }

        FILTER (!BOUND(?termEnd) || ?termEnd > NOW())
        FILTER (!BOUND(?termReplacedBy))
        #{label_service}
      } ORDER BY ?termStart ?term
    SPARQL
  end

  def query_executive_index(country)
    country = "wd:#{country}" unless country.start_with?('wd:')
    <<~SPARQL
      SELECT DISTINCT ?executive ?executiveLabel ?adminArea ?adminAreaLabel ?adminAreaType ?adminAreaTypeLabel ?position ?positionLabel {
        {
          #{select_admin_areas_for_country(country)}
        }

        OPTIONAL {
          {
            ?position p:P1001 [ wikibase:rank ?appliesToJurisdictionRank ; ps:P1001 ?adminArea ] ;
              wdt:P31/wdt:P279* wd:Q4164871 .
            FILTER (?appliesToJurisdictionRank != wikibase:DeprecatedRank)
            FILTER EXISTS {
              VALUES ?positionSuperclass { wd:Q2285706 wd:Q30461 }
              ?position wdt:P279* ?positionSuperclass .
            }
          } UNION {
            ?adminArea wdt:P1313 ?position
          }

          OPTIONAL {
            ?position wdt:P361 ?executive .
            # Exclude executives that are privy councils
            FILTER NOT EXISTS { ?executive wdt:P31/wdt:P279* wd:Q6528244 }
            # Exclude executives which aren't direct parents of the position
            FILTER NOT EXISTS { ?position wdt:P361 ?other . ?other wdt:P361+ ?executive }
          }
        }

        #{label_service}
      } ORDER BY ?primarySort ?country ?adminAreaType ?executive ?position
    SPARQL
  end
end
