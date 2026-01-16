# frozen_string_literal: true

require 'set'
require_relative "iso8583/version"
require_relative "iso8583/errors"
require_relative "iso8583/field"
require_relative "iso8583/field_definitions"
require_relative "iso8583/codec"
require_relative "iso8583/bitmap"

# ISO 8583 Financial Messaging Library
# 
# This module provides a complete implementation of the ISO 8583 standard
# for financial transaction messages. It supports encoding, decoding, and
# validation of messages with multiple encoding formats.
#
# @example Basic usage
#   message = Iso8583::Message.new
#   message.mti = "0200"
#   message[2] = "4111111111111111"
#   encoded = message.encode
#
module Iso8583
  class << self
    # Library version
    # @return [String]
    def version
      VERSION
    end

    # Enable debug mode
    # @return [Boolean]
    attr_accessor :debug

    # Debug output
    # @param msg [String] Debug message
    def debug(msg)
      puts "[ISO8583 DEBUG] #{msg}" if @debug
    end
  end
end
