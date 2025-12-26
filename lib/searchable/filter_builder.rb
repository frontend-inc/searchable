# frozen_string_literal: true

module Searchable
  class FilterBuilder
    BOOLEAN_CLASSES = [TrueClass, FalseClass].freeze
    JSONB_DELIMITER = "."

    class << self
      def build_condition(filter)
        field = filter[:field]
        operator = filter[:operator]
        value = filter[:value]

        jsonb_column, field_name = parse_jsonb_field(field)

        if jsonb_column
          build_jsonb_condition(jsonb_column, field_name, operator, value)
        else
          build_standard_condition(field, operator, value)
        end
      end

      def build_sort_condition(order)
        return nil unless order

        sort_by = order[:sort_by]
        sort_direction = order[:sort_direction]

        jsonb_column, field_name = parse_jsonb_field(sort_by)

        if jsonb_column
          Arel.sql("#{jsonb_column} ->> '#{field_name}' #{sort_direction}")
        else
          { sort_by.to_sym => sort_direction }
        end
      end

      private

      def parse_jsonb_field(field)
        parts = field.to_s.split(JSONB_DELIMITER)
        return [nil, field] if parts.length < 2

        [parts[0], parts[1]]
      end

      def build_standard_condition(field, operator, value)
        condition = "#{field} #{operator} (?)"
        [condition, value]
      end

      def build_jsonb_condition(jsonb_column, field_name, operator, value)
        formatted_value = format_jsonb_value(value)

        condition = if operator == "BETWEEN"
                      "#{jsonb_column} ->> '#{field_name}' #{operator} ? AND ?"
                    else
                      "#{jsonb_column} ->> '#{field_name}' #{operator} (?)"
                    end

        [condition, formatted_value]
      end

      def format_jsonb_value(value)
        if BOOLEAN_CLASSES.include?(value.class)
          value.to_json
        else
          value
        end
      end
    end
  end
end
