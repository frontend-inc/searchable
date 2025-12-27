# frozen_string_literal: true

module Searchable
  class QueryParser
    DEFAULT_PER_PAGE = 20
    DELIMITER = ":"

    OPERATORS = {
      gt: ">",
      gte: ">=",
      lt: "<",
      lte: "<=",
      eq: "=",
      neq: "!=",
      in: "IN",
      nin: "NOT IN"
    }.freeze

    ARRAY_OPERATORS = %w[in nin].freeze
    DATE_REGEX = /\A\d{4}-\d{2}-\d{2}\z/
    BOOLEAN_STRINGS = %w[true false null].freeze

    # Reserved params that are not filters
    RESERVED_PARAMS = %w[page per_page query format].freeze

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

    def query
      @params[:query]
    end

    def query?
      query.present?
    end

    def filters
      filter_params.map do |key, value|
        parse_filter_param(key.to_s, value)
      end
    end

    def filters?
      filters.any?
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
        query: query,
        page: page,
        per_page: per_page
      }
    end

    private

    def filter_params
      params_hash = @params.respond_to?(:to_unsafe_h) ? @params.to_unsafe_h : @params.to_h
      params_hash.reject { |key, _| RESERVED_PARAMS.include?(extract_field_name(key.to_s)) }
    end

    def extract_field_name(key)
      key.split(DELIMITER).first
    end

    def parse_filter_param(key, value)
      field, operator_key = key.split(DELIMITER, 2)
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

      value.to_s.split(",").map { |v| transform_value(v.strip) }
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
