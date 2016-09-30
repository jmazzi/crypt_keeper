# This module is used to verify CryptKeeper log subscribers work as expected.
#
# Examples
#
# The following test will verify that the `input` query is scrubbed so it
# matches the `output` query.
#
#   specify do
#     should_log_scrubbed_query \
#       input:  "SELECT pgp_sym_encrypt('val', 'key')"
#       output: "SELECT encrypt([FILTERED])"
#   end
#
# The following test will verify that the `input` query was not logged at all
# (eg: CryptKeeper.silence_logs is enabled).
#
#   specify do
#     CryptKeeper.silence_logs = true
#
#     should_not_log_query input: "SELECT pgp_sym_encrypt('val', 'key')"
#   end
module CryptKeeper
  module Testing
    module Logging
      class TestDebugLogSubscriber < ActiveRecord::LogSubscriber
        attr_reader :debugs

        def initialize
          @debugs = []
          super
        end

        def debug(message)
          @debugs << message
        end
      end

      # Public: Verifies that the given input query was scrubbed and the
      # output query was logged.
      #
      # input - Input SQL query to be scrubbed
      # output - Expected output SQL query after scrubbing
      #
      # Returns nothing.
      def should_log_scrubbed_query(input:, output:)
        queries = sql(input)

        valid_input = queries.none? { |line| line.include? input }
        expect(valid_input).to eq(true), "found unscrubbed SQL query logged!"

        valid_output = queries.any? { |line| line.include? output }
        expect(valid_output).to eq(true), "output query was not logged!"
      end

      # Public: Verifies that the given input query was not logged.
      #
      # input - SQL query
      #
      # Returns nothing.
      def should_not_log_query(input)
        queries = sql(input)

        expect(queries).to be_empty

        valid_output = sql("SELECT 1").any? { |line| line.include? "SELECT 1" }

        expect(valid_output).to eq(true)
      end

      private

      # Private: Triggers ActiveRecord::LogSubscriber#sql for the given query.
      #
      # query - SQL query
      #
      # Returns an Array.
      def sql(query)
        event = ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: query })

        subscriber = TestDebugLogSubscriber.new
        subscriber.sql event
        subscriber.debugs
      end
    end
  end
end

RSpec.configure do |c|
  c.include CryptKeeper::Testing::Logging
end
