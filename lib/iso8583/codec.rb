# frozen_string_literal: true

module Iso8583
  # Base codec class for encoding/decoding field values
  class Codec
    # Encode a field value
    # @param field [Field] Field definition
    # @param value [String] Value to encode
    # @return [String] Encoded value
    def encode(field, value)
      raise NotImplementedError, 'Subclasses must implement encode'
    end

    # Decode a field value
    # @param field [Field] Field definition
    # @param data [String] Binary data to decode
    # @param offset [Integer] Starting offset in data
    # @return [Array<String, Integer>] Decoded value and bytes consumed
    def decode(field, data, offset = 0)
      raise NotImplementedError, 'Subclasses must implement decode'
    end

    protected

    # Encode length indicator
    # @param length [Integer] Length value
    # @param indicator_size [Integer] Number of digits (2, 3, or 4)
    # @return [String] Encoded length
    def encode_length(length, indicator_size)
      length.to_s.rjust(indicator_size, '0')
    end

    # Decode length indicator
    # @param data [String] Data containing length
    # @param offset [Integer] Starting offset
    # @param indicator_size [Integer] Number of digits
    # @return [Integer] Decoded length
    def decode_length(data, offset, indicator_size)
      length_str = data[offset, indicator_size]
      if length_str.nil? || length_str.length < indicator_size
        raise ParseError,
              'Insufficient data for length indicator'
      end

      length_str.to_i
    end
  end

  # ASCII codec - encodes values as ASCII text
  class AsciiCodec < Codec
    def encode(field, value)
      value_str = value.to_s

      if field.variable_length?
        field.validate!(value_str)
        length_indicator = encode_length(value_str.length, field.length_indicator_size)
        length_indicator + value_str
      else
        # Pad fixed length fields before validation
        value_str = value_str.ljust(field.max_length)
        field.validate!(value_str)
        value_str
      end
    end

    def decode(field, data, offset = 0)
      pos = offset

      if field.variable_length?
        # Read length indicator
        length = decode_length(data, pos, field.length_indicator_size)
        pos += field.length_indicator_size

        # Validate length
        raise ParseError, "Field #{field.number}: length #{length} exceeds max #{field.max_length}" if length > field.max_length

        # Read value
        value = data[pos, length]
        raise ParseError, "Insufficient data for field #{field.number}" if value.nil? || value.length < length

        pos += length
      else
        # Fixed length
        value = data[pos, field.max_length]
        raise ParseError, "Insufficient data for field #{field.number}" if value.nil? || value.length < field.max_length

        pos += field.max_length
        value = value.rstrip # Remove padding
      end

      [value, pos - offset]
    end
  end

  # BCD codec - encodes numeric values in Binary Coded Decimal
  class BcdCodec < Codec
    def encode(field, value)
      value_str = value.to_s
      field.validate!(value_str)

      # BCD encoding: each byte contains 2 digits
      # Pad with leading zero if odd length
      bcd_str = value_str.length.odd? ? "0#{value_str}" : value_str

      # Convert pairs of digits to bytes
      bytes = []
      (0...bcd_str.length).step(2) do |i|
        high = bcd_str[i].to_i
        low = bcd_str[i + 1].to_i
        bytes << ((high << 4) | low)
      end

      encoded = bytes.pack('C*')

      if field.variable_length?
        # Length in BCD (number of digits, not bytes)
        length_indicator = encode_length(value_str.length, field.length_indicator_size)
        length_indicator + encoded
      else
        encoded
      end
    end

    def decode(field, data, offset = 0)
      pos = offset
      value_length = field.max_length

      if field.variable_length?
        # Read ASCII length indicator
        value_length = decode_length(data, pos, field.length_indicator_size)
        pos += field.length_indicator_size
      end

      # Calculate bytes needed
      bcd_bytes = (value_length + 1) / 2

      bcd_data = data[pos, bcd_bytes]
      if bcd_data.nil? || bcd_data.bytesize < bcd_bytes
        raise ParseError,
              "Insufficient BCD data for field #{field.number}"
      end

      # Decode BCD to string
      value = +'' # Unfrozen string
      bcd_data.bytes.each do |byte|
        high = (byte >> 4) & 0x0F
        low = byte & 0x0F
        value << high.to_s << low.to_s
      end

      # Remove leading zero if original length was odd
      value = value[1..] if value_length.odd?
      value = value[0, value_length]

      pos += bcd_bytes

      [value, pos - offset]
    end
  end

  # Binary codec - handles binary data (no conversion)
  class BinaryCodec < Codec
    def encode(field, value)
      value_str = value.to_s

      # For binary fields, we don't validate format
      if field.variable_length?
        if value_str.bytesize > field.max_length
          raise InvalidLengthError,
                "Field #{field.number}: binary data size #{value_str.bytesize} exceeds max #{field.max_length}"
        end

        length_indicator = encode_length(value_str.bytesize, field.length_indicator_size)
        length_indicator + value_str
      else
        if value_str.bytesize != field.max_length
          raise InvalidLengthError,
                "Field #{field.number}: expected binary size #{field.max_length}, got #{value_str.bytesize}"
        end
        value_str
      end
    end

    def decode(field, data, offset = 0)
      pos = offset

      if field.variable_length?
        # Read ASCII length indicator
        length = decode_length(data, pos, field.length_indicator_size)
        pos += field.length_indicator_size

        raise ParseError, "Field #{field.number}: binary length #{length} exceeds max #{field.max_length}" if length > field.max_length

        value = data[pos, length]
        raise ParseError, "Insufficient binary data for field #{field.number}" if value.nil? || value.bytesize < length

        pos += length
      else
        value = data[pos, field.max_length]
        if value.nil? || value.bytesize < field.max_length
          raise ParseError,
                "Insufficient binary data for field #{field.number}"
        end

        pos += field.max_length
      end

      [value, pos - offset]
    end
  end

  # Codec factory
  module CodecFactory
    @codecs = {
      ascii: AsciiCodec.new,
      bcd: BcdCodec.new,
      binary: BinaryCodec.new
    }

    # Get codec by name
    # @param name [Symbol] Codec name (:ascii, :bcd, :binary)
    # @return [Codec]
    def self.get(name)
      @codecs[name] || raise(ArgumentError, "Unknown codec: #{name}")
    end

    # Register a custom codec
    # @param name [Symbol] Codec name
    # @param codec [Codec] Codec instance
    def self.register(name, codec)
      @codecs[name] = codec
    end
  end
end
