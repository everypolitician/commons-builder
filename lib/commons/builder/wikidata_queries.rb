# frozen_string_literal: true

require 'liquid'

class WikidataQueries < Wikidata
  def query_legislative(position_item_id:, house_item_id:, term_item_id: nil, start_date: nil, end_date: nil, **_rest)
    templated_query('legislative',
                    position_item_id: position_item_id,
                    house_item_id: house_item_id,
                    term_item_id: term_item_id,
                    start_date: start_date,
                    end_date: end_date)
  end

  def query_executive(executive_item_id:, positions:, **_rest)
    templated_query('executive',
                    executive_item_id: executive_item_id,
                    position_item_ids: positions.map(&:position_item_id))
  end

  def select_admin_areas_for_country(country)
    templated_query('select_admin_areas_for_country',
                    country: country)
  end

  def query_legislative_index(country)
    templated_query('legislative_index',
                    country: country)
  end

  def query_legislative_index_terms(*houses)
    templated_query('legislative_index_terms',
                    houses: houses)
  end

  def query_executive_index(country)
    templated_query('executive_index',
                    country: country)
  end

  class LangTag < Liquid::Tag
    def variable(prefix, lang_code, query = true)
      variable = "#{prefix}_#{lang_code.tr('-', '_')}"
      variable = "?#{variable}" if query
      variable
    end
  end

  class LangSelect < LangTag
    def initialize(_tag_name, prefix, options)
      @prefix = Liquid::Variable.new(prefix, options)
    end

    def render(context)
      context['languages'].map { |l| variable(@prefix.render(context), l) }.join(' ')
    end
  end

  class LangOptions < LangTag
    def initialize(_tag_name, params, options)
      params = params.split
      @prefix = Liquid::Variable.new(params[0], options)
      @item = Liquid::Variable.new(params[1], options)
    end

    def render(context)
      context['languages'].map do |l|
        <<~CLAUSE
          OPTIONAL {
            #{@item.render(context)} rdfs:label #{variable(@prefix.render(context), l)}
            FILTER(LANG(#{variable(@prefix.render(context), l)}) = \"#{l}\")
          }
        CLAUSE
      end.join("\n")
    end
  end

  def templated_query_from_string(name, query, options = {})
    Liquid::Template.file_system = Liquid::LocalFileSystem.new(Pathname.new(__dir__).join('queries'), '%s.rq.liquid')
    Liquid::Template.register_tag('lang_select', LangSelect)
    Liquid::Template.register_tag('lang_options', LangOptions)

    @templated_queries ||= {}
    @templated_queries[name] ||= Liquid::Template.parse(query, error_mode: :strict)

    options = options.map { |k, v| [k.to_s, v] }.to_h
    options['languages'] = languages
    options['self'] = self

    @templated_queries[name].render!(options)
  end

  def templated_query(name, options = {})
    templated_query_from_string name, Pathname.new(__dir__).join('queries', name + '.rq.liquid').read, options
  end
end
