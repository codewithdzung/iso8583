# frozen_string_literal: true

module Iso8583
  # Handles ISO 8583 bitmap encoding and decoding
  # Bitmap indicates which data elements are present in the message
  # Primary bitmap (fields 1-64) is always present
  # Secondary bitmap (fields 65-128) is present if bit 1 is set
  class Bitmap
    attr_reader :fields

    # Initialize a new Bitmap
    # @param fields [Array<Integer>] List of field numbers that are present
    def initialize(fields = [])
      @fields = Set.new(fields.reject { |f| f < 1 || f > 128 })
    end

    # Set a field as present
    # @param field_num [Integer] Field number (1-128)
    def set(field_num)
      raise ArgumentError, 'Field number must be between 1 and 128' unless (1..128).cover?(field_num)

      @fields.add(field_num)
    end

    # Unset a field (mark as not present)
    # @param field_num [Integer] Field number (1-128)
    def unset(field_num)
      @fields.delete(field_num)
    end

    # Check if a field is present
    # @param field_num [Integer] Field number (1-128)
    # @return [Boolean]
    def set?(field_num)
      @fields.include?(field_num)
    end

    # Check if secondary bitmap is needed (any field > 64 is set)
    # @return [Boolean]
    def secondary_bitmap?
      @fields.any? { |f| f > 64 }
    end

    # Encode bitmap to binary string (8 or 16 bytes)
    # @return [String] Binary encoded bitmap
    def encode_binary
      bytes = Array.new(8, 0)

      # Set bit 1 if secondary bitmap is needed
      if secondary_bitmap?
        bytes[0] |= 0x80
        bytes += Array.new(8, 0)
      end

      # Set bits for each field
      @fields.each do |field|
        next if field < 1 || field > 128

        # Determine which bitmap (primary or secondary)
        if field <= 64
          byte_index = (field - 1) / 8
          bit_index = 7 - ((field - 1) % 8)
        else
          byte_index = 8 + ((field - 65) / 8)
          bit_index = 7 - ((field - 65) % 8)
        end

        bytes[byte_index] |= (1 << bit_index)
      end

      bytes.pack('C*')
    end

    # Encode bitmap to hexadecimal string
    # @return [String] Hex encoded bitmap (16 or 32 characters)
    def encode_hex
      encode_binary.unpack1('H*').upcase
    end

    # Parse binary bitmap
    # @param data [String] Binary bitmap data (at least 8 bytes)
    # @return [Bitmap] New Bitmap instance
    def self.parse_binary(data)
      raise ArgumentError, 'Bitmap data must be at least 8 bytes' if data.bytesize < 8

      fields = []
      bytes = data.bytes

      # Check if secondary bitmap is present (bit 1 of first byte)
      has_secondary = bytes[0].anybits?(0x80)

      raise ArgumentError, 'Insufficient data for secondary bitmap' if has_secondary && data.bytesize < 16

      # Parse primary bitmap (fields 2-64)
      (0...8).each do |byte_index|
        byte = bytes[byte_index]
        (0...8).each do |bit_index|
          field = (byte_index * 8) + (7 - bit_index) + 1
          next if field == 1 # Skip bit 1 (reserved for secondary bitmap indicator)

          fields << field if (byte & (1 << bit_index)) != 0
        end
      end

      # Parse secondary bitmap (fields 65-128) if present
      if has_secondary
        (8...16).each do |byte_index|
          byte = bytes[byte_index]
          (0...8).each do |bit_index|
            field = ((byte_index - 8) * 8) + (7 - bit_index) + 65
            fields << field if (byte & (1 << bit_index)) != 0
          end
        end
      end

      new(fields)
    end

    # Parse hexadecimal bitmap
    # @param hex [String] Hexadecimal bitmap (16 or 32 characters)
    # @return [Bitmap] New Bitmap instance
    def self.parse_hex(hex)
      raise ArgumentError, 'Hex bitmap must be at least 16 characters' if hex.length < 16

      binary = [hex[0...32]].pack('H*')
      parse_binary(binary)
    end

    # Get list of present fields in sorted order
    # @return [Array<Integer>] Sorted list of field numbers
    def to_a
      @fields.to_a.sort
    end

    # String representation
    # @return [String]
    def to_s
      "Bitmap[#{to_a.join(', ')}]"
    end

    # Detailed inspection
    # @return [String]
    def inspect
      "#<Iso8583::Bitmap fields=#{to_a.inspect} secondary=#{secondary_bitmap?}>"
    end

    # Check equality
    # @param other [Bitmap]
    # @return [Boolean]
    def ==(other)
      other.is_a?(Bitmap) && @fields == other.instance_variable_get(:@fields)
    end

    alias eql? ==

    # Hash code for using in hashes
    # @return [Integer]
    def hash
      @fields.hash
    end
  end
end
