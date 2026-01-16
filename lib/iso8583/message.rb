# frozen_string_literal: true

module Iso8583
  # Represents an ISO 8583 message
  class Message
    attr_reader :fields, :mti

    # Initialize a new message
    # @param mti [String, nil] Message Type Indicator (4 digits)
    # @param fields [Hash, nil] Initial field values
    def initialize(mti: nil, fields: {})
      @fields = {}
      @mti = nil

      self.mti = mti if mti
      fields.each { |num, value| self[num] = value }
    end

    # Set MTI (Message Type Indicator)
    # @param value [String] 4-digit MTI
    def mti=(value)
      value_str = value.to_s
      raise InvalidFormatError, "MTI must be 4 digits, got: #{value_str.inspect}" unless value_str.match?(/^\d{4}$/)

      @mti = value_str
    end

    # Get field value
    # @param field_num [Integer] Field number
    # @return [String, nil]
    def [](field_num)
      @fields[field_num]
    end

    # Set field value
    # @param field_num [Integer] Field number
    # @param value [String] Field value
    def []=(field_num, value)
      field_num = field_num.to_i
      raise InvalidFieldError, 'Field number must be 1-128' unless (1..128).cover?(field_num)

      if value.nil?
        @fields.delete(field_num)
      else
        # Validate field if definition exists
        if FieldDefinitions.defined?(field_num)
          field_def = FieldDefinitions.get(field_num)
          field_def.validate!(value)
        end

        @fields[field_num] = value.to_s
      end
    end

    # Check if field is present
    # @param field_num [Integer] Field number
    # @return [Boolean]
    def has_field?(field_num)
      @fields.key?(field_num)
    end

    # Remove a field
    # @param field_num [Integer] Field number
    def delete_field(field_num)
      @fields.delete(field_num)
    end

    # Get all present field numbers
    # @return [Array<Integer>]
    def field_numbers
      @fields.keys.sort
    end

    # Encode message to binary format
    # @param encoding [Symbol] Default encoding for undefined fields (:ascii, :bcd, :binary)
    # @return [String] Encoded message
    def encode(encoding: :ascii)
      raise MissingFieldError, 'MTI is required' unless @mti

      result = +''

      # Encode MTI
      result << @mti

      # Create bitmap
      bitmap = Bitmap.new(field_numbers)
      result << bitmap.encode_binary

      # Encode each field
      field_numbers.each do |field_num|
        value = @fields[field_num]

        # Get field definition or create a generic one
        field_def = FieldDefinitions.get(field_num)
        unless field_def
          # For undefined fields, use generic encoding
          Iso8583.debug("Field #{field_num} not defined, using generic #{encoding} encoding")
          next # Skip undefined fields for now
        end

        # Get appropriate codec
        codec = CodecFactory.get(field_def.encoding)
        encoded = codec.encode(field_def, value)
        result << encoded
      end

      result
    end

    # Parse message from binary format
    # @param data [String] Binary message data
    # @param encoding [Symbol] Default encoding for undefined fields
    # @return [Message] Parsed message
    def self.parse(data, encoding: :ascii)
      raise ParseError, 'Message data cannot be empty' if data.nil? || data.empty?

      offset = 0

      # Parse MTI (4 ASCII digits)
      mti = data[offset, 4]
      raise ParseError, 'Invalid MTI' unless mti && mti.length == 4

      offset += 4

      # Parse bitmap
      raise ParseError, 'Insufficient data for bitmap' if data.bytesize < offset + 8

      bitmap = Bitmap.parse_binary(data[offset..-1])
      bitmap_size = bitmap.secondary_bitmap? ? 16 : 8
      offset += bitmap_size

      # Create message
      message = new(mti: mti)

      # Parse each field indicated by bitmap
      bitmap.to_a.each do |field_num|
        field_def = FieldDefinitions.get(field_num)
        unless field_def
          Iso8583.debug("Field #{field_num} not defined, skipping")
          next
        end

        # Get appropriate codec
        codec = CodecFactory.get(field_def.encoding)

        begin
          value, bytes_consumed = codec.decode(field_def, data, offset)
          message[field_num] = value
          offset += bytes_consumed
        rescue StandardError => e
          raise ParseError, "Error parsing field #{field_num}: #{e.message}"
        end
      end

      message
    end

    # Convert to hash representation
    # @return [Hash]
    def to_h
      {
        mti: @mti,
        fields: @fields.dup
      }
    end

    # Convert to string representation
    # @return [String]
    def to_s
      fields_str = field_numbers.map { |num| "#{num}=#{@fields[num].inspect}" }.join(', ')
      "ISO8583 Message MTI=#{@mti} [#{fields_str}]"
    end

    # Detailed inspection
    # @return [String]
    def inspect
      "#<Iso8583::Message mti=#{@mti.inspect} fields=#{@fields.inspect}>"
    end

    # Clone the message
    # @return [Message]
    def clone
      Message.new(mti: @mti, fields: @fields.dup)
    end

    # Check equality
    # @param other [Message]
    # @return [Boolean]
    def ==(other)
      other.is_a?(Message) && @mti == other.mti && @fields == other.fields
    end

    alias eql? ==

    # Human-readable representation
    # @return [String]
    def pretty_print
      lines = ['ISO 8583 Message', '=' * 50]
      lines << "MTI: #{@mti}"
      lines << ''
      lines << 'Fields:'

      field_numbers.each do |field_num|
        field_def = FieldDefinitions.get(field_num)
        field_name = field_def ? field_def.name : 'Unknown'
        value = @fields[field_num]

        # Format binary data as hex
        display_value = if field_def&.encoding == :binary
                          value.unpack1('H*')
                        else
                          value
                        end

        lines << format('  %3d: %-40s = %s', field_num, field_name, display_value)
      end

      lines.join("\n")
    end
  end
end
