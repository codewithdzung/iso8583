# frozen_string_literal: true

module Iso8583
  # Base error class for all ISO8583 errors
  class Error < StandardError; end

  # Raised when validation fails
  class ValidationError < Error; end

  # Raised when parsing fails
  class ParseError < Error; end

  # Raised when encoding fails
  class EncodingError < Error; end

  # Raised when a required field is missing
  class MissingFieldError < Error; end

  # Raised when an invalid field number is used
  class InvalidFieldError < Error; end

  # Raised when field length is invalid
  class InvalidLengthError < ValidationError; end

  # Raised when field format is invalid
  class InvalidFormatError < ValidationError; end
end
