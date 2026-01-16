# frozen_string_literal: true

module Iso8583
  # Represents an ISO 8583 field definition
  class Field
    # Field data types
    TYPES = {
      numeric: /^\d+$/,
      alpha: /^[A-Za-z]+$/,
      alphanumeric: /^[A-Za-z0-9]+$/,
      alphanumeric_special: /^[ -~]+$/, # Printable ASCII
      binary: //, # Any binary data
      track2: /^[0-9=D]+$/, # Track 2 data format
      amount: /^\d{12}$/ # 12-digit amount
    }.freeze

    # Length encoding types
    LENGTH_TYPES = %i[fixed llvar lllvar llllvar].freeze

    # Content encoding formats
    ENCODING_FORMATS = %i[ascii bcd binary].freeze

    attr_reader :number, :name, :length_type, :max_length, :data_type, :encoding

    # Initialize a field definition
    # @param number [Integer] Field number (0-128)
    # @param name [String] Field name/description
    # @param length_type [Symbol] :fixed, :llvar, :lllvar, :llllvar
    # @param max_length [Integer] Maximum length
    # @param data_type [Symbol] Type from TYPES
    # @param encoding [Symbol] :ascii, :bcd, or :binary
    def initialize(number:, name:, length_type:, max_length:, data_type: :alphanumeric_special, encoding: :ascii)
      validate_params!(number, length_type, data_type, encoding)

      @number = number
      @name = name
      @length_type = length_type
      @max_length = max_length
      @data_type = data_type
      @encoding = encoding
    end

    # Validate field value
    # @param value [String] Value to validate
    # @return [Boolean] true if valid
    # @raise [ValidationError] if invalid
    def validate!(value)
      return true if value.nil?

      value_str = value.to_s

      # Check length
      validate_length!(value_str)

      # Check data type format
      validate_format!(value_str)

      true
    end

    # Check if field has variable length
    # @return [Boolean]
    def variable_length?
      length_type != :fixed
    end

    # Get length indicator size (in digits)
    # @return [Integer]
    def length_indicator_size
      case length_type
      when :llvar then 2
      when :lllvar then 3
      when :llllvar then 4
      else 0
      end
    end

    # String representation
    # @return [String]
    def to_s
      "Field #{number}: #{name} (#{length_type}, max=#{max_length}, type=#{data_type})"
    end

    # Detailed inspection
    # @return [String]
    def inspect
      "#<Iso8583::Field number=#{number} name=#{name.inspect} " \
        "length_type=#{length_type} max_length=#{max_length} " \
        "data_type=#{data_type} encoding=#{encoding}>"
    end

    private

    def validate_params!(number, length_type, data_type, encoding)
      raise ArgumentError, 'Field number must be 0-128' unless (0..128).cover?(number)
      raise ArgumentError, "Invalid length type: #{length_type}" unless LENGTH_TYPES.include?(length_type)
      raise ArgumentError, "Invalid data type: #{data_type}" unless TYPES.key?(data_type)
      raise ArgumentError, "Invalid encoding: #{encoding}" unless ENCODING_FORMATS.include?(encoding)
    end

    def validate_length!(value)
      if length_type == :fixed
        if value.length != max_length
          raise InvalidLengthError,
                "Field #{number} (#{name}): expected length #{max_length}, got #{value.length}"
        end
      elsif value.length > max_length
        raise InvalidLengthError,
              "Field #{number} (#{name}): maximum length #{max_length}, got #{value.length}"
      end
    end

    def validate_format!(value)
      pattern = TYPES[data_type]
      return if pattern.match?(value)

      raise InvalidFormatError,
            "Field #{number} (#{name}): invalid format for #{data_type}. Value: #{value.inspect}"
    end
  end
end
