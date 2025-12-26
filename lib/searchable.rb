# frozen_string_literal: true

require "active_support"
require "active_support/concern"
require "active_record"

require_relative "searchable/version"
require_relative "searchable/configuration"
require_relative "searchable/query_parser"
require_relative "searchable/filter_builder"
require_relative "searchable/concern"

module Searchable
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
