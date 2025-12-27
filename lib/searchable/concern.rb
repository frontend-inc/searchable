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
        @searchable_actions
      end
    end

    def searchable(scope)
      scope = apply_filters(scope)
      scope = apply_search(scope)
      scope = apply_sort(scope)
      scope = apply_pagination(scope)
      scope
    end

    def query_parser
      @query_parser ||= QueryParser.new(request.query_parameters)
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
      list = self.class.searchable_actions_list
      list.nil? || list.include?(action_name.to_sym)
    end

    def initialize_query_parser
      @query_parser = QueryParser.new(request.query_parameters)
    end

    def apply_filters(scope)
      return scope unless query_parser.filters?

      conditions = []
      values = []
      column_names = scope.klass.column_names

      query_parser.filters.each do |filter|
        base_field = filter[:field].to_s.split(FilterBuilder::JSONB_DELIMITER).first
        next unless column_names.include?(base_field)

        condition, value = FilterBuilder.build_condition(filter)
        conditions << condition
        values << value
      end

      return scope if conditions.empty?

      sql = conditions.join(" AND ")
      scope.where(sql, *values)
    end

    def apply_search(scope)
      return scope unless query_parser.query?

      if scope.respond_to?(:pg_search)
        scope.pg_search(query_parser.query)
      elsif scope.respond_to?(:search)
        scope.search(query_parser.query)
      else
        scope
      end
    end

    def apply_sort(scope)
      column_names = scope.klass.column_names

      sort_info = if query_parser.sort?
                    query_parser.sort
                  elsif column_names.include?("created_at")
                    { field: "created_at", direction: :desc }
                  end

      return scope unless sort_info && column_names.include?(sort_info[:field])

      scope.order(sort_info[:field] => sort_info[:direction])
    end

    def apply_pagination(scope)
      scope.page(query_parser.page).per(query_parser.per_page)
    end
  end
end
