# frozen_string_literal: true

require 'liquid'

class WikidataQueries
  class LangTag < Liquid::Tag
    include SPARQLLanguageHelper
  end

  class LangSelect < LangTag
    def initialize(_tag_name, prefix, options)
      @prefix = Liquid::Variable.new(prefix, options)
    end

    def render(context)
      context['config']['languages'].map { |l| variable(@prefix.render(context), l) }.join(' ')
    end
  end

  class LangOptions < LangTag
    def initialize(_tag_name, params, options)
      params = params.split
      @prefix = Liquid::Variable.new(params[0], options)
      @item = Liquid::Variable.new(params[1], options)
    end

    def render(context)
      context['config']['languages'].map do |l|
        <<~CLAUSE
          OPTIONAL {
            #{@item.render(context)} rdfs:label #{variable(@prefix.render(context), l)}
            FILTER(LANG(#{variable(@prefix.render(context), l)}) = \"#{l}\")
          }
        CLAUSE
      end.join("\n")
    end
  end

  def initialize(config)
    @config = config
  end

  def templated_query_from_string(name, query, options = {})
    Liquid::Template.file_system = Liquid::LocalFileSystem.new(Pathname.new(__dir__).join('queries'), '%s.rq.liquid')
    Liquid::Template.register_tag('lang_select', LangSelect)
    Liquid::Template.register_tag('lang_options', LangOptions)

    @templated_queries ||= {}
    @templated_queries[name] ||= Liquid::Template.parse(query, error_mode: :strict)

    options = options.map { |k, v| [k.to_s, v] }.to_h
    options['config'] = config
    options['self'] = self

    @templated_queries[name].render!(options)
  end

  def templated_query(name, options = {})
    templated_query_from_string name, Pathname.new(__dir__).join('queries', name + '.rq.liquid').read, options
  end

  private

  attr_reader :config
end
