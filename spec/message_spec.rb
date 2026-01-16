# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iso8583::Message do
  describe '#initialize' do
    it 'creates empty message' do
      message = described_class.new

      expect(message.mti).to be_nil
      expect(message.field_numbers).to be_empty
    end

    it 'creates message with MTI' do
      message = described_class.new(mti: '0200')

      expect(message.mti).to eq('0200')
    end

    it 'creates message with fields' do
      message = described_class.new(
        mti: '0200',
        fields: { 2 => '4111111111111111', 3 => '000000' }
      )

      expect(message.mti).to eq('0200')
      expect(message[2]).to eq('4111111111111111')
      expect(message[3]).to eq('000000')
    end
  end

  describe '#mti=' do
    let(:message) { described_class.new }

    it 'sets valid MTI' do
      message.mti = '0200'
      expect(message.mti).to eq('0200')
    end

    it 'raises error for invalid MTI' do
      expect { message.mti = '123' }.to raise_error(Iso8583::InvalidFormatError)
      expect { message.mti = 'ABCD' }.to raise_error(Iso8583::InvalidFormatError)
      expect { message.mti = '12345' }.to raise_error(Iso8583::InvalidFormatError)
    end
  end

  describe '#[] and #[]=' do
    let(:message) { described_class.new }

    it 'sets and gets field value' do
      message[2] = '4111111111111111'
      expect(message[2]).to eq('4111111111111111')
    end

    it 'validates field with definition' do
      expect do
        message[4] = '123' # Amount must be 12 digits
      end.to raise_error(Iso8583::InvalidLengthError)
    end

    it 'allows valid field values' do
      message[4] = '000000012345'
      expect(message[4]).to eq('000000012345')
    end

    it 'raises error for invalid field number' do
      expect { message[0] = 'value' }.to raise_error(Iso8583::InvalidFieldError)
      expect { message[129] = 'value' }.to raise_error(Iso8583::InvalidFieldError)
    end

    it 'deletes field when set to nil' do
      message[2] = '4111111111111111'
      message[2] = nil
      expect(message[2]).to be_nil
    end
  end

  describe '#has_field?' do
    let(:message) { described_class.new }

    it 'returns true for present field' do
      message[2] = '4111111111111111'
      expect(message.has_field?(2)).to be true
    end

    it 'returns false for absent field' do
      expect(message.has_field?(2)).to be false
    end
  end

  describe '#delete_field' do
    let(:message) { described_class.new }

    it 'removes field' do
      message[2] = '4111111111111111'
      message.delete_field(2)
      expect(message.has_field?(2)).to be false
    end
  end

  describe '#field_numbers' do
    let(:message) { described_class.new }

    it 'returns sorted field numbers' do
      message[11] = '123456'
      message[3] = '000000'
      message[2] = '4111111111111111'

      expect(message.field_numbers).to eq([2, 3, 11])
    end
  end

  describe '#encode and .parse' do
    it 'encodes and parses simple message' do
      original = described_class.new(mti: '0200')
      original[2] = '4111111111111111'
      original[3] = '000000'
      original[4] = '000000012345'

      encoded = original.encode
      parsed = described_class.parse(encoded)

      expect(parsed.mti).to eq(original.mti)
      expect(parsed[2]).to eq(original[2])
      expect(parsed[3]).to eq(original[3])
      expect(parsed[4]).to eq(original[4])
    end

    it 'handles multiple fields' do
      original = described_class.new(mti: '0200')
      original[2] = '5200000000000001'
      original[3] = '000000'
      original[4] = '000000050000'
      original[7] = '0110153540'
      original[11] = '123456'
      original[39] = '00'
      original[41] = 'TERM0001'
      original[49] = '840'

      encoded = original.encode
      parsed = described_class.parse(encoded)

      expect(parsed.mti).to eq('0200')
      expect(parsed.field_numbers).to eq(original.field_numbers)

      original.field_numbers.each do |field_num|
        expect(parsed[field_num]).to eq(original[field_num])
      end
    end

    it 'handles variable length fields' do
      original = described_class.new(mti: '0100')
      original[2] = '411111'  # Short PAN
      original[32] = '12345'  # Acquiring Institution ID

      encoded = original.encode
      parsed = described_class.parse(encoded)

      expect(parsed[2]).to eq('411111')
      expect(parsed[32]).to eq('12345')
    end

    it 'handles secondary bitmap' do
      original = described_class.new(mti: '0200')
      original[2] = '4111111111111111'
      original[3] = '000000'
      original[100] = '12345' # Field > 64, triggers secondary bitmap

      encoded = original.encode
      parsed = described_class.parse(encoded)

      expect(parsed[2]).to eq(original[2])
      expect(parsed[3]).to eq(original[3])
      expect(parsed[100]).to eq(original[100])
    end

    it 'raises error for missing MTI' do
      message = described_class.new
      message[2] = '4111111111111111'

      expect { message.encode }.to raise_error(Iso8583::MissingFieldError)
    end

    it 'raises error for invalid data' do
      expect do
        described_class.parse('')
      end.to raise_error(Iso8583::ParseError)

      expect do
        described_class.parse('123')
      end.to raise_error(Iso8583::ParseError)
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      message = described_class.new(mti: '0200')
      message[2] = '4111111111111111'
      message[3] = '000000'

      hash = message.to_h

      expect(hash[:mti]).to eq('0200')
      expect(hash[:fields][2]).to eq('4111111111111111')
      expect(hash[:fields][3]).to eq('000000')
    end
  end

  describe '#clone' do
    it 'creates independent copy' do
      original = described_class.new(mti: '0200')
      original[2] = '4111111111111111'

      cloned = original.clone
      cloned[3] = '000000'

      expect(original.has_field?(3)).to be false
      expect(cloned.has_field?(3)).to be true
    end
  end

  describe '#==' do
    it 'compares messages correctly' do
      msg1 = described_class.new(mti: '0200', fields: { 2 => '4111111111111111' })
      msg2 = described_class.new(mti: '0200', fields: { 2 => '4111111111111111' })
      msg3 = described_class.new(mti: '0210', fields: { 2 => '4111111111111111' })

      expect(msg1).to eq(msg2)
      expect(msg1).not_to eq(msg3)
    end
  end

  describe '#pretty_print' do
    it 'generates human-readable output' do
      message = described_class.new(mti: '0200')
      message[2] = '4111111111111111'
      message[3] = '000000'
      message[4] = '000000012345'

      output = message.pretty_print

      expect(output).to include('ISO 8583 Message')
      expect(output).to include('MTI: 0200')
      expect(output).to include('Primary Account Number')
      expect(output).to include('4111111111111111')
    end
  end

  describe 'real-world scenarios' do
    it 'handles authorization request' do
      # Authorization request
      message = described_class.new(mti: '0100')
      message[2] = '5200000000000001' # PAN
      message[3] = '000000'              # Processing Code
      message[4] = '000000100000'        # Amount
      message[7] = '0625153540'          # Transmission Date/Time
      message[11] = '123456'             # STAN
      message[41] = 'TERMINAL'           # Terminal ID
      message[49] = '840'                # Currency Code

      encoded = message.encode
      parsed = described_class.parse(encoded)

      expect(parsed.mti).to eq('0100')
      expect(parsed.field_numbers.length).to eq(7)
    end

    it 'handles financial transaction' do
      # Financial transaction request
      message = described_class.new(mti: '0200')
      message[2] = '4111111111111111'
      message[3] = '000000'
      message[4] = '000000050000'
      message[11] = '654321'
      message[39] = '00' # Response Code
      message[41] = 'ATM00001'

      encoded = message.encode
      expect(encoded).to be_a(String)
      expect(encoded.bytesize).to be > 0

      parsed = described_class.parse(encoded)
      expect(parsed).to eq(message)
    end
  end
end
