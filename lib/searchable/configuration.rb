# frozen_string_literal: true

module Searchable
  class Configuration
    attr_accessor :default_per_page, :max_per_page, :search_method

    def initialize
      @default_per_page = 20
      @max_per_page = 100
      @search_method = :pg_search
    end
  end
end
