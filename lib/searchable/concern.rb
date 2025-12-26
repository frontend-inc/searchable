# frozen_string_literal: true

module Searchable
  module Concern
    extend ActiveSupport::Concern

    included do
      before_action :initialize_query_parser, if: :should_parse_query?
    end

    class_methods do
      def searchable_actions(*actions)
        @searchable_actions = actions.map(&:to_sym)
      end

      def searchable_actions_list
        @searchable_actions || [:index]
      end
    end

    def searchable(scope)
      scope = apply_includes(scope)
      scope = apply_filters(scope)
      scope = apply_search(scope)
      scope = apply_sort(scope)
      scope = apply_pagination(scope)
      scope
    end

    def query_parser
      @query_parser ||= QueryParser.new(params)
    end

    def page_info(resources)
      total = resources.respond_to?(:total_count) ? resources.total_count : 0
      pages_per = [query_parser.per_page.to_f, 1].max

      {
        page: query_parser.page,
        per_page: query_parser.per_page,
        num_pages: total.zero? ? 1 : (total / pages_per).ceil,
        total_count: total
      }
    end

    private

    def should_parse_query?
      self.class.searchable_actions_list.include?(action_name.to_sym)
    end

    def initialize_query_parser
      @query_parser = QueryParser.new(params)
    end

    def apply_includes(scope)
      return scope unless query_parser.includes?

      scope.includes(*query_parser.includes.map(&:to_sym))
    end

    def apply_filters(scope)
      return scope unless query_parser.filters?

      conditions = []
      values = []

      query_parser.filters.each do |filter|
        condition, value = FilterBuilder.build_condition(filter)
        conditions << condition

        if filter[:operator] == "BETWEEN"
          values.concat(value[0..1])
        else
          values << value
        end
      end

      sql = conditions.join(" AND ")
      scope.where(sql, *values)
    end

    def apply_search(scope)
      return scope unless query_parser.keywords?

      if scope.respond_to?(:pg_search)
        scope.pg_search(query_parser.keywords)
      elsif scope.respond_to?(:search)
        scope.search(query_parser.keywords)
      else
        scope
      end
    end

    def apply_sort(scope)
      return scope unless query_parser.order?

      condition = FilterBuilder.build_sort_condition(query_parser.order)
      scope.order(condition)
    end

    def apply_pagination(scope)
      scope.page(query_parser.page).per(query_parser.per_page)
    end
  end
end
