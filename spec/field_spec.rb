# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iso8583::Field do
  describe '#initialize' do
    it 'creates a valid field' do
      field = described_class.new(
        number: 2,
        name: 'PAN',
        length_type: :llvar,
        max_length: 19,
        data_type: :numeric,
        encoding: :ascii
      )

      expect(field.number).to eq(2)
      expect(field.name).to eq('PAN')
      expect(field.length_type).to eq(:llvar)
      expect(field.max_length).to eq(19)
      expect(field.data_type).to eq(:numeric)
      expect(field.encoding).to eq(:ascii)
    end

    it 'uses default data_type and encoding' do
      field = described_class.new(
        number: 43,
        name: 'Card Acceptor Name',
        length_type: :fixed,
        max_length: 40
      )

      expect(field.data_type).to eq(:alphanumeric_special)
      expect(field.encoding).to eq(:ascii)
    end

    it 'raises error for invalid field number' do
      expect do
        described_class.new(
          number: 129,
          name: 'Invalid',
          length_type: :fixed,
          max_length: 10
        )
      end.to raise_error(ArgumentError, /Field number must be 0-128/)
    end

    it 'raises error for invalid length type' do
      expect do
        described_class.new(
          number: 2,
          name: 'Test',
          length_type: :invalid,
          max_length: 10
        )
      end.to raise_error(ArgumentError, /Invalid length type/)
    end

    it 'raises error for invalid data type' do
      expect do
        described_class.new(
          number: 2,
          name: 'Test',
          length_type: :fixed,
          max_length: 10,
          data_type: :invalid
        )
      end.to raise_error(ArgumentError, /Invalid data type/)
    end

    it 'raises error for invalid encoding' do
      expect do
        described_class.new(
          number: 2,
          name: 'Test',
          length_type: :fixed,
          max_length: 10,
          encoding: :invalid
        )
      end.to raise_error(ArgumentError, /Invalid encoding/)
    end
  end

  describe '#validate!' do
    context 'with numeric field' do
      let(:field) do
        described_class.new(
          number: 4,
          name: 'Amount',
          length_type: :fixed,
          max_length: 12,
          data_type: :numeric
        )
      end

      it 'accepts valid numeric value' do
        expect(field.validate!('000000012345')).to be true
      end

      it 'rejects non-numeric value' do
        expect do
          field.validate!('12345ABCDEFG')  # 12 chars but contains letters
        end.to raise_error(Iso8583::InvalidFormatError, /invalid format/)
      end

      it 'rejects wrong length for fixed field' do
        expect do
          field.validate!('123')
        end.to raise_error(Iso8583::InvalidLengthError, /expected length 12/)
      end
    end

    context 'with variable length field' do
      let(:field) do
        described_class.new(
          number: 2,
          name: 'PAN',
          length_type: :llvar,
          max_length: 19,
          data_type: :numeric
        )
      end

      it 'accepts value within max length' do
        expect(field.validate!('4111111111111111')).to be true
        expect(field.validate!('12345')).to be true
      end

      it 'rejects value exceeding max length' do
        expect do
          field.validate!('12345678901234567890')
        end.to raise_error(Iso8583::InvalidLengthError, /maximum length 19/)
      end
    end

    context 'with alphanumeric field' do
      let(:field) do
        described_class.new(
          number: 37,
          name: 'RRN',
          length_type: :fixed,
          max_length: 12,
          data_type: :alphanumeric
        )
      end

      it 'accepts alphanumeric value' do
        expect(field.validate!('ABC123XYZ789')).to be true
      end

      it 'rejects special characters' do
        expect do
          field.validate!('ABC-12345678')  # 12 chars but contains special char
        end.to raise_error(Iso8583::InvalidFormatError)
      end
    end

    context 'with alphanumeric_special field' do
      let(:field) do
        described_class.new(
          number: 43,
          name: 'Card Acceptor Name',
          length_type: :fixed,
          max_length: 40,
          data_type: :alphanumeric_special
        )
      end

      it 'accepts alphanumeric with special chars' do
        # Exactly 40 characters with special chars
        value = 'Store Name 123, Street #45              '
        expect(value.length).to eq(40)
        expect(field.validate!(value)).to be true
      end
    end

    context 'with track2 field' do
      let(:field) do
        described_class.new(
          number: 35,
          name: 'Track 2',
          length_type: :llvar,
          max_length: 37,
          data_type: :track2
        )
      end

      it 'accepts valid track2 data' do
        expect(field.validate!('4111111111111111=25121011234567890')).to be true
        expect(field.validate!('4111111111111111D25121011234567890')).to be true
      end

      it 'rejects invalid track2 data' do
        expect do
          field.validate!('4111-1111-1111-1111')
        end.to raise_error(Iso8583::InvalidFormatError)
      end
    end

    it 'accepts nil value' do
      field = described_class.new(
        number: 2,
        name: 'PAN',
        length_type: :llvar,
        max_length: 19
      )

      expect(field.validate!(nil)).to be true
    end
  end

  describe '#variable_length?' do
    it 'returns false for fixed length' do
      field = described_class.new(
        number: 4,
        name: 'Amount',
        length_type: :fixed,
        max_length: 12
      )

      expect(field.variable_length?).to be false
    end

    it 'returns true for llvar' do
      field = described_class.new(
        number: 2,
        name: 'PAN',
        length_type: :llvar,
        max_length: 19
      )

      expect(field.variable_length?).to be true
    end
  end

  describe '#length_indicator_size' do
    it 'returns 0 for fixed length' do
      field = described_class.new(
        number: 4,
        name: 'Amount',
        length_type: :fixed,
        max_length: 12
      )

      expect(field.length_indicator_size).to eq(0)
    end

    it 'returns 2 for llvar' do
      field = described_class.new(
        number: 2,
        name: 'PAN',
        length_type: :llvar,
        max_length: 19
      )

      expect(field.length_indicator_size).to eq(2)
    end

    it 'returns 3 for lllvar' do
      field = described_class.new(
        number: 55,
        name: 'ICC Data',
        length_type: :lllvar,
        max_length: 255
      )

      expect(field.length_indicator_size).to eq(3)
    end

    it 'returns 4 for llllvar' do
      field = described_class.new(
        number: 63,
        name: 'Private',
        length_type: :llllvar,
        max_length: 9999
      )

      expect(field.length_indicator_size).to eq(4)
    end
  end
end
