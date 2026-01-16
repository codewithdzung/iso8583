# frozen_string_literal: true

module Iso8583
  # Standard ISO 8583 field definitions
  # Based on ISO 8583:1987 specification
  module FieldDefinitions
    # Define standard fields
    FIELDS = {
      0 => Field.new(
        number: 0,
        name: "Message Type Indicator (MTI)",
        length_type: :fixed,
        max_length: 4,
        data_type: :numeric,
        encoding: :ascii
      ),
      2 => Field.new(
        number: 2,
        name: "Primary Account Number (PAN)",
        length_type: :llvar,
        max_length: 19,
        data_type: :numeric,
        encoding: :ascii
      ),
      3 => Field.new(
        number: 3,
        name: "Processing Code",
        length_type: :fixed,
        max_length: 6,
        data_type: :numeric,
        encoding: :ascii
      ),
      4 => Field.new(
        number: 4,
        name: "Amount, Transaction",
        length_type: :fixed,
        max_length: 12,
        data_type: :numeric,
        encoding: :ascii
      ),
      7 => Field.new(
        number: 7,
        name: "Transmission Date & Time",
        length_type: :fixed,
        max_length: 10,
        data_type: :numeric,
        encoding: :ascii
      ),
      11 => Field.new(
        number: 11,
        name: "System Trace Audit Number (STAN)",
        length_type: :fixed,
        max_length: 6,
        data_type: :numeric,
        encoding: :ascii
      ),
      12 => Field.new(
        number: 12,
        name: "Local Transaction Time",
        length_type: :fixed,
        max_length: 6,
        data_type: :numeric,
        encoding: :ascii
      ),
      13 => Field.new(
        number: 13,
        name: "Local Transaction Date",
        length_type: :fixed,
        max_length: 4,
        data_type: :numeric,
        encoding: :ascii
      ),
      14 => Field.new(
        number: 14,
        name: "Card Expiration Date",
        length_type: :fixed,
        max_length: 4,
        data_type: :numeric,
        encoding: :ascii
      ),
      18 => Field.new(
        number: 18,
        name: "Merchant Type",
        length_type: :fixed,
        max_length: 4,
        data_type: :numeric,
        encoding: :ascii
      ),
      22 => Field.new(
        number: 22,
        name: "Point of Service Entry Mode",
        length_type: :fixed,
        max_length: 3,
        data_type: :numeric,
        encoding: :ascii
      ),
      25 => Field.new(
        number: 25,
        name: "Point of Service Condition Code",
        length_type: :fixed,
        max_length: 2,
        data_type: :numeric,
        encoding: :ascii
      ),
      28 => Field.new(
        number: 28,
        name: "Amount, Transaction Fee",
        length_type: :fixed,
        max_length: 9,
        data_type: :numeric,
        encoding: :ascii
      ),
      32 => Field.new(
        number: 32,
        name: "Acquiring Institution ID",
        length_type: :llvar,
        max_length: 11,
        data_type: :numeric,
        encoding: :ascii
      ),
      35 => Field.new(
        number: 35,
        name: "Track 2 Data",
        length_type: :llvar,
        max_length: 37,
        data_type: :track2,
        encoding: :ascii
      ),
      37 => Field.new(
        number: 37,
        name: "Retrieval Reference Number",
        length_type: :fixed,
        max_length: 12,
        data_type: :alphanumeric,
        encoding: :ascii
      ),
      38 => Field.new(
        number: 38,
        name: "Authorization ID Response",
        length_type: :fixed,
        max_length: 6,
        data_type: :alphanumeric,
        encoding: :ascii
      ),
      39 => Field.new(
        number: 39,
        name: "Response Code",
        length_type: :fixed,
        max_length: 2,
        data_type: :alphanumeric,
        encoding: :ascii
      ),
      41 => Field.new(
        number: 41,
        name: "Card Acceptor Terminal ID",
        length_type: :fixed,
        max_length: 8,
        data_type: :alphanumeric_special,
        encoding: :ascii
      ),
      42 => Field.new(
        number: 42,
        name: "Card Acceptor ID Code",
        length_type: :fixed,
        max_length: 15,
        data_type: :alphanumeric_special,
        encoding: :ascii
      ),
      43 => Field.new(
        number: 43,
        name: "Card Acceptor Name/Location",
        length_type: :fixed,
        max_length: 40,
        data_type: :alphanumeric_special,
        encoding: :ascii
      ),
      49 => Field.new(
        number: 49,
        name: "Currency Code, Transaction",
        length_type: :fixed,
        max_length: 3,
        data_type: :numeric,
        encoding: :ascii
      ),
      52 => Field.new(
        number: 52,
        name: "Personal ID Number (PIN) Data",
        length_type: :fixed,
        max_length: 16,
        data_type: :binary,
        encoding: :binary
      ),
      54 => Field.new(
        number: 54,
        name: "Additional Amounts",
        length_type: :lllvar,
        max_length: 120,
        data_type: :alphanumeric_special,
        encoding: :ascii
      ),
      55 => Field.new(
        number: 55,
        name: "ICC Data - EMV",
        length_type: :lllvar,
        max_length: 255,
        data_type: :binary,
        encoding: :binary
      ),
      62 => Field.new(
        number: 62,
        name: "Custom Payment Service Data",
        length_type: :lllvar,
        max_length: 999,
        data_type: :alphanumeric_special,
        encoding: :ascii
      ),
      63 => Field.new(
        number: 63,
        name: "Private Data",
        length_type: :lllvar,
        max_length: 999,
        data_type: :alphanumeric_special,
        encoding: :ascii
      ),
      90 => Field.new(
        number: 90,
        name: "Original Data Elements",
        length_type: :fixed,
        max_length: 42,
        data_type: :numeric,
        encoding: :ascii
      ),
      95 => Field.new(
        number: 95,
        name: "Replacement Amounts",
        length_type: :fixed,
        max_length: 42,
        data_type: :alphanumeric_special,
        encoding: :ascii
      ),
      100 => Field.new(
        number: 100,
        name: "Receiving Institution ID",
        length_type: :llvar,
        max_length: 11,
        data_type: :numeric,
        encoding: :ascii
      ),
      102 => Field.new(
        number: 102,
        name: "Account ID 1",
        length_type: :llvar,
        max_length: 28,
        data_type: :alphanumeric_special,
        encoding: :ascii
      ),
      103 => Field.new(
        number: 103,
        name: "Account ID 2",
        length_type: :llvar,
        max_length: 28,
        data_type: :alphanumeric_special,
        encoding: :ascii
      ),
      128 => Field.new(
        number: 128,
        name: "Message Authentication Code (MAC)",
        length_type: :fixed,
        max_length: 16,
        data_type: :binary,
        encoding: :binary
      )
    }.freeze

    # Get field definition by number
    # @param number [Integer] Field number
    # @return [Field, nil]
    def self.get(number)
      FIELDS[number]
    end

    # Check if field is defined
    # @param number [Integer] Field number
    # @return [Boolean]
    def self.defined?(number)
      FIELDS.key?(number)
    end

    # Get all defined field numbers
    # @return [Array<Integer>]
    def self.all_numbers
      FIELDS.keys.sort
    end
  end
end
