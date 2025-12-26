# frozen_string_literal: true

module Searchable
  class QueryParser
    DEFAULT_PER_PAGE = 20
    SORT_DIRECTIONS = %w[asc desc].freeze
    DELIMITER = ":"

    OPERATORS = {
      gt: ">",
      gte: ">=",
      lt: "<",
      lte: "<=",
      eq: "=",
      neq: "!=",
      in: "IN",
      nin: "NOT IN",
      btw: "BETWEEN"
    }.freeze

    ARRAY_OPERATORS = %w[in nin btw].freeze
    DATE_REGEX = /\A\d{4}-\d{2}-\d{2}\z/
    BOOLEAN_STRINGS = %w[true false null].freeze

    # Comma not inside square braces
    FILTER_DELIMITER = /
      ,         # match comma
      (?!       # if not followed by
      [^\[]*    # anything except an open brace [
      \]        # followed by a closing brace ]
      )         # end lookahead
    /x

    DATE_PERIODS = %i[second minute hour day week month quarter year].freeze

    AGGREGATIONS = {
      avg: "average",
      sum: "sum",
      min: "minimum",
      max: "maximum",
      count: "count"
    }.freeze

    DYNAMIC_VALUES = {
      _1_day_ago: -> { 1.day.ago },
      _7_days_ago: -> { 7.days.ago },
      _14_days_ago: -> { 14.days.ago },
      _30_days_ago: -> { 30.days.ago },
      _60_days_ago: -> { 60.days.ago },
      _90_days_ago: -> { 90.days.ago },
      _current_year: -> { Time.current.year },
      _current_time: -> { Time.current },
      _1_day: -> { 1.day.from_now },
      _7_days: -> { 7.days.from_now },
      _14_days: -> { 14.days.from_now },
      _30_days: -> { 30.days.from_now },
      _60_days: -> { 60.days.from_now },
      _90_days: -> { 90.days.from_now },
      _next_year: -> { Time.current.advance(years: 1).year }
    }.freeze

    attr_reader :params

    def initialize(params)
      @params = params
    end

    def keywords
      return nil unless @params[:keywords]

      if @params[:keywords].include?(DELIMITER)
        @params[:keywords].split(DELIMITER)
      else
        @params[:keywords]
      end
    end

    def keywords?
      keywords.present?
    end

    def select_fields
      return [] unless @params[:select]

      @params[:select].split(",").map do |field|
        field_name, aggregation = field.strip.split(DELIMITER)

        if aggregation.present? && AGGREGATIONS.key?(aggregation.to_sym)
          [field_name, AGGREGATIONS[aggregation.to_sym]]
        else
          [field_name]
        end
      end
    end

    def select?
      select_fields.any?
    end

    def order
      return nil unless @params[:order]

      sort_by, sort_direction = @params[:order].split(DELIMITER)
      sort_direction = "desc" unless SORT_DIRECTIONS.include?(sort_direction)

      { sort_by: sort_by, sort_direction: sort_direction }
    end

    def order?
      order.present?
    end

    def includes
      return nil unless @params[:include]

      @params[:include].split(",").map(&:strip)
    end

    def includes?
      includes.present?
    end

    def filters
      return [] unless @params[:filters]

      @params[:filters].split(FILTER_DELIMITER).map do |filter_param|
        parse_filter(filter_param)
      end
    end

    def filters?
      filters.any?
    end

    def group_by
      return [] unless @params[:group_by].present?

      @params[:group_by].split(",").map do |field|
        field_name, date_period = field.strip.split(DELIMITER)

        if date_period.present? && DATE_PERIODS.include?(date_period.to_sym)
          [field_name, date_period]
        else
          [field_name]
        end
      end
    end

    def page
      @params[:page]&.to_i || 1
    end

    def per_page
      @params[:per_page]&.to_i || DEFAULT_PER_PAGE
    end

    def to_h
      {
        filters: filters,
        group_by: group_by,
        includes: includes,
        keywords: keywords,
        order: order,
        page: page,
        per_page: per_page,
        select_fields: select_fields
      }
    end

    private

    def parse_filter(filter_param)
      field, operator_key, value = filter_param.split(DELIMITER, 3)
      operator_key = "eq" unless OPERATORS.key?(operator_key&.to_sym)
      operator = OPERATORS[operator_key.to_sym]

      parsed_value = if ARRAY_OPERATORS.include?(operator_key)
                       parse_array_value(value)
                     else
                       transform_value(value)
                     end

      { field: field, operator: operator, value: parsed_value }
    end

    def parse_array_value(value)
      return [] unless value

      value.gsub(/\A\[|\]\z/, "").split(",").map { |v| transform_value(v.strip) }
    end

    def transform_value(value)
      return value unless value.is_a?(String)

      dynamic_key = "_#{value}".to_sym

      if DYNAMIC_VALUES.key?(dynamic_key)
        DYNAMIC_VALUES[dynamic_key].call
      elsif value.match?(DATE_REGEX)
        DateTime.parse(value)
      elsif BOOLEAN_STRINGS.include?(value)
        case value
        when "true" then true
        when "false" then false
        when "null" then nil
        end
      else
        value
      end
    end
  end
end
