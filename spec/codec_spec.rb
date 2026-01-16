# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iso8583::AsciiCodec do
  let(:codec) { described_class.new }

  describe '#encode and #decode' do
    context 'with fixed length field' do
      let(:field) do
        Iso8583::Field.new(
          number: 39,
          name: 'Response Code',
          length_type: :fixed,
          max_length: 2,
          data_type: :alphanumeric
        )
      end

      it 'encodes and decodes correctly' do
        value = '00'
        encoded = codec.encode(field, value)

        expect(encoded).to eq('00')

        decoded, bytes_consumed = codec.decode(field, encoded)
        expect(decoded).to eq('00')
        expect(bytes_consumed).to eq(2)
      end

      it 'pads short values' do
        # Use alphanumeric_special field which allows spaces
        field = Iso8583::Field.new(
          number: 41,
          name: 'Terminal ID',
          length_type: :fixed,
          max_length: 8,
          data_type: :alphanumeric_special
        )

        value = 'TERM1'
        encoded = codec.encode(field, value)

        expect(encoded).to eq('TERM1   ')  # Padded with spaces to 8 chars
        expect(encoded.length).to eq(8)
      end
    end

    context 'with llvar field' do
      let(:field) do
        Iso8583::Field.new(
          number: 2,
          name: 'PAN',
          length_type: :llvar,
          max_length: 19,
          data_type: :numeric
        )
      end

      it 'encodes and decodes with length indicator' do
        value = '4111111111111111'
        encoded = codec.encode(field, value)

        expect(encoded).to eq('164111111111111111')
        expect(encoded[0, 2]).to eq('16')  # Length indicator

        decoded, bytes_consumed = codec.decode(field, encoded)
        expect(decoded).to eq(value)
        expect(bytes_consumed).to eq(18) # 2 (length) + 16 (value)
      end
    end

    context 'with lllvar field' do
      let(:field) do
        Iso8583::Field.new(
          number: 63,
          name: 'Private Data',
          length_type: :lllvar,
          max_length: 999,
          data_type: :alphanumeric_special
        )
      end

      it 'encodes and decodes with 3-digit length indicator' do
        value = 'TEST DATA'
        encoded = codec.encode(field, value)

        expect(encoded).to eq('009TEST DATA')
        expect(encoded[0, 3]).to eq('009')

        decoded, bytes_consumed = codec.decode(field, encoded)
        expect(decoded).to eq(value)
        expect(bytes_consumed).to eq(12)
      end
    end
  end

  describe 'error handling' do
    let(:field) do
      Iso8583::Field.new(
        number: 2,
        name: 'PAN',
        length_type: :llvar,
        max_length: 19,
        data_type: :numeric
      )
    end

    it 'raises error for insufficient data' do
      expect do
        codec.decode(field, '16411') # Length says 16 but only 3 digits provided
      end.to raise_error(Iso8583::ParseError, /Insufficient data/)
    end

    it 'raises error when length exceeds max' do
      # Length indicator says 99 (exceeds max of 19)
      expect do
        codec.decode(field, '99' + '1' * 99)
      end.to raise_error(Iso8583::ParseError, /exceeds max/)
    end
  end
end

RSpec.describe Iso8583::BcdCodec do
  let(:codec) { described_class.new }

  describe '#encode and #decode' do
    context 'with fixed length numeric field' do
      let(:field) do
        Iso8583::Field.new(
          number: 4,
          name: 'Amount',
          length_type: :fixed,
          max_length: 12,
          data_type: :numeric,
          encoding: :bcd
        )
      end

      it 'encodes to BCD format' do
        value = '000000012345'
        encoded = codec.encode(field, value)

        # 12 digits = 6 bytes in BCD
        expect(encoded.bytesize).to eq(6)
        expect(encoded.unpack1('H*')).to eq('000000012345')
      end

      it 'decodes from BCD format' do
        # BCD: 000000012345
        bcd_data = [0x00, 0x00, 0x00, 0x01, 0x23, 0x45].pack('C*')

        decoded, bytes_consumed = codec.decode(field, bcd_data)
        expect(decoded).to eq('000000012345')
        expect(bytes_consumed).to eq(6)
      end

      it 'handles odd length values' do
        field = Iso8583::Field.new(
          number: 11,
          name: 'STAN',
          length_type: :fixed,
          max_length: 6,
          data_type: :numeric,
          encoding: :bcd
        )

        value = '123456'
        encoded = codec.encode(field, value)

        expect(encoded.bytesize).to eq(3)

        decoded, = codec.decode(field, encoded)
        expect(decoded).to eq(value)
      end
    end

    context 'with llvar field' do
      let(:field) do
        Iso8583::Field.new(
          number: 2,
          name: 'PAN',
          length_type: :llvar,
          max_length: 19,
          data_type: :numeric,
          encoding: :bcd
        )
      end

      it 'encodes with ASCII length indicator' do
        value = '4111111111111111'
        encoded = codec.encode(field, value)

        # Length indicator is ASCII "16"
        expect(encoded[0, 2]).to eq('16')
        # Followed by 8 bytes of BCD
        expect(encoded.bytesize).to eq(2 + 8)
      end

      it 'decodes with ASCII length indicator' do
        # "16" + BCD(4111111111111111)
        bcd_value = [0x41, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11].pack('C*')
        data = '16' + bcd_value

        decoded, bytes_consumed = codec.decode(field, data)
        expect(decoded).to eq('4111111111111111')
        expect(bytes_consumed).to eq(10) # 2 (ASCII length) + 8 (BCD)
      end
    end
  end

  describe 'round-trip encoding' do
    it 'preserves value through encode/decode cycle' do
      field = Iso8583::Field.new(
        number: 4,
        name: 'Amount',
        length_type: :fixed,
        max_length: 12,
        data_type: :numeric,
        encoding: :bcd
      )

      values = %w[000000012345 000000000001 999999999999]

      values.each do |value|
        encoded = codec.encode(field, value)
        decoded, = codec.decode(field, encoded)
        expect(decoded).to eq(value)
      end
    end
  end
end

RSpec.describe Iso8583::BinaryCodec do
  let(:codec) { described_class.new }

  describe '#encode and #decode' do
    context 'with fixed length binary field' do
      let(:field) do
        Iso8583::Field.new(
          number: 52,
          name: 'PIN Block',
          length_type: :fixed,
          max_length: 16,
          data_type: :binary,
          encoding: :binary
        )
      end

      it 'encodes binary data as-is' do
        value = "\x01\x02\x03\x04" + "\x00" * 12
        encoded = codec.encode(field, value)

        expect(encoded).to eq(value)
        expect(encoded.bytesize).to eq(16)
      end

      it 'decodes binary data as-is' do
        data = "\x01\x02\x03\x04" + "\x00" * 12

        decoded, bytes_consumed = codec.decode(field, data)
        expect(decoded).to eq(data)
        expect(bytes_consumed).to eq(16)
      end
    end

    context 'with lllvar binary field' do
      let(:field) do
        Iso8583::Field.new(
          number: 55,
          name: 'ICC Data',
          length_type: :lllvar,
          max_length: 255,
          data_type: :binary,
          encoding: :binary
        )
      end

      it 'encodes with ASCII length indicator' do
        value = "\x9F\x02\x06\x00\x00\x00\x01\x00\x00" # Sample EMV tag
        encoded = codec.encode(field, value)

        # Length in ASCII
        expect(encoded[0, 3]).to eq('009')
        expect(encoded[3..-1]).to eq(value)
        expect(encoded.bytesize).to eq(3 + 9)
      end

      it 'decodes with ASCII length indicator' do
        value = "\x9F\x02\x06\x00\x00\x00\x01\x00\x00"
        data = '009' + value

        decoded, bytes_consumed = codec.decode(field, data)
        expect(decoded).to eq(value)
        expect(bytes_consumed).to eq(12)
      end
    end
  end

  describe 'error handling' do
    let(:field) do
      Iso8583::Field.new(
        number: 52,
        name: 'PIN Block',
        length_type: :fixed,
        max_length: 16,
        data_type: :binary,
        encoding: :binary
      )
    end

    it 'raises error for wrong size' do
      expect do
        codec.encode(field, "\x01\x02\x03") # Only 3 bytes, needs 16
      end.to raise_error(Iso8583::InvalidLengthError)
    end
  end
end

RSpec.describe Iso8583::CodecFactory do
  describe '.get' do
    it 'returns ASCII codec' do
      codec = described_class.get(:ascii)
      expect(codec).to be_a(Iso8583::AsciiCodec)
    end

    it 'returns BCD codec' do
      codec = described_class.get(:bcd)
      expect(codec).to be_a(Iso8583::BcdCodec)
    end

    it 'returns Binary codec' do
      codec = described_class.get(:binary)
      expect(codec).to be_a(Iso8583::BinaryCodec)
    end

    it 'raises error for unknown codec' do
      expect do
        described_class.get(:unknown)
      end.to raise_error(ArgumentError, /Unknown codec/)
    end
  end

  describe '.register' do
    it 'allows registering custom codec' do
      custom_codec = Iso8583::AsciiCodec.new
      described_class.register(:custom, custom_codec)

      expect(described_class.get(:custom)).to eq(custom_codec)
    end
  end
end
