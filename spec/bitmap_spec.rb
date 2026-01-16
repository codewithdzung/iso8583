# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iso8583::Bitmap do
  describe '#initialize' do
    it 'creates an empty bitmap' do
      bitmap = described_class.new
      expect(bitmap.to_a).to be_empty
    end

    it 'creates bitmap with specified fields' do
      bitmap = described_class.new([2, 3, 4])
      expect(bitmap.to_a).to eq([2, 3, 4])
    end

    it 'ignores invalid field numbers' do
      bitmap = described_class.new([0, 2, 3, 129, 200])
      expect(bitmap.to_a).to eq([2, 3])
    end
  end

  describe '#set and #unset' do
    let(:bitmap) { described_class.new }

    it 'sets a field' do
      bitmap.set(2)
      expect(bitmap.set?(2)).to be true
    end

    it 'unsets a field' do
      bitmap.set(2)
      bitmap.unset(2)
      expect(bitmap.set?(2)).to be false
    end

    it 'raises error for invalid field numbers' do
      expect { bitmap.set(0) }.to raise_error(ArgumentError)
      expect { bitmap.set(129) }.to raise_error(ArgumentError)
    end
  end

  describe '#secondary_bitmap?' do
    it 'returns false when no fields > 64' do
      bitmap = described_class.new([2, 3, 64])
      expect(bitmap.secondary_bitmap?).to be false
    end

    it 'returns true when fields > 64 exist' do
      bitmap = described_class.new([2, 65])
      expect(bitmap.secondary_bitmap?).to be true
    end
  end

  describe '#encode_binary' do
    it 'encodes primary bitmap only' do
      bitmap = described_class.new([2, 3, 4])
      binary = bitmap.encode_binary
      
      expect(binary.bytesize).to eq(8)
      # Field 2, 3, 4 should be set
      # Binary: 01110000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
      expect(binary.bytes[0]).to eq(0x70)
    end

    it 'encodes with secondary bitmap' do
      bitmap = described_class.new([2, 65])
      binary = bitmap.encode_binary
      
      expect(binary.bytesize).to eq(16)
      # Bit 1 should be set for secondary bitmap
      expect(binary.bytes[0] & 0x80).to eq(0x80)
    end

    it 'encodes all fields correctly' do
      bitmap = described_class.new([2, 7, 11, 39, 41, 70])
      binary = bitmap.encode_binary
      
      # Verify by parsing back
      parsed = described_class.parse_binary(binary)
      expect(parsed.to_a).to eq([2, 7, 11, 39, 41, 70])
    end
  end

  describe '#encode_hex' do
    it 'encodes to hexadecimal' do
      bitmap = described_class.new([2, 3, 4])
      hex = bitmap.encode_hex
      
      expect(hex).to be_a(String)
      expect(hex.length).to eq(16)
      expect(hex).to match(/^[0-9A-F]+$/)
    end

    it 'encodes with secondary bitmap to 32 hex chars' do
      bitmap = described_class.new([2, 65])
      hex = bitmap.encode_hex
      
      expect(hex.length).to eq(32)
    end
  end

  describe '.parse_binary' do
    it 'parses primary bitmap' do
      # Set fields 2, 3, 4
      binary = [0x70, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00].pack('C*')
      bitmap = described_class.parse_binary(binary)
      
      expect(bitmap.to_a).to eq([2, 3, 4])
    end

    it 'parses secondary bitmap' do
      # Set bit 1 and field 2 in primary, field 65 in secondary
      primary = [0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00].pack('C*')
      secondary = [0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00].pack('C*')
      binary = primary + secondary
      
      bitmap = described_class.parse_binary(binary)
      expect(bitmap.to_a).to include(2, 65)
    end

    it 'raises error for insufficient data' do
      expect { described_class.parse_binary('short') }.to raise_error(ArgumentError)
    end
  end

  describe '.parse_hex' do
    it 'parses hexadecimal bitmap' do
      hex = '7000000000000000'
      bitmap = described_class.parse_hex(hex)
      
      expect(bitmap.to_a).to eq([2, 3, 4])
    end

    it 'raises error for invalid hex' do
      expect { described_class.parse_hex('short') }.to raise_error(ArgumentError)
    end
  end

  describe 'round-trip encoding' do
    it 'preserves fields through encode/decode cycle' do
      original_fields = [2, 3, 4, 7, 11, 12, 28, 39, 41, 42, 63]
      bitmap = described_class.new(original_fields)
      
      # Binary round-trip
      binary = bitmap.encode_binary
      parsed = described_class.parse_binary(binary)
      expect(parsed.to_a).to eq(original_fields)
      
      # Hex round-trip
      hex = bitmap.encode_hex
      parsed = described_class.parse_hex(hex)
      expect(parsed.to_a).to eq(original_fields)
    end

    it 'preserves fields with secondary bitmap' do
      original_fields = [2, 7, 11, 39, 65, 70, 90, 128]
      bitmap = described_class.new(original_fields)
      
      binary = bitmap.encode_binary
      parsed = described_class.parse_binary(binary)
      expect(parsed.to_a).to eq(original_fields)
    end
  end

  describe '#==' do
    it 'compares bitmaps correctly' do
      bitmap1 = described_class.new([2, 3, 4])
      bitmap2 = described_class.new([2, 3, 4])
      bitmap3 = described_class.new([2, 3, 5])
      
      expect(bitmap1).to eq(bitmap2)
      expect(bitmap1).not_to eq(bitmap3)
    end
  end
end
