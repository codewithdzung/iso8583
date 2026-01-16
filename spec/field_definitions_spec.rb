# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iso8583::FieldDefinitions do
  describe '.get' do
    it 'returns field definition for valid field number' do
      field = described_class.get(2)
      
      expect(field).to be_a(Iso8583::Field)
      expect(field.number).to eq(2)
      expect(field.name).to include("Primary Account Number")
    end

    it 'returns nil for undefined field' do
      expect(described_class.get(999)).to be_nil
    end
  end

  describe '.defined?' do
    it 'returns true for defined field' do
      expect(described_class.defined?(2)).to be true
      expect(described_class.defined?(39)).to be true
    end

    it 'returns false for undefined field' do
      expect(described_class.defined?(999)).to be false
    end
  end

  describe '.all_numbers' do
    it 'returns sorted list of all defined fields' do
      numbers = described_class.all_numbers
      
      expect(numbers).to be_an(Array)
      expect(numbers).to include(0, 2, 3, 4, 39, 128)
      expect(numbers).to eq(numbers.sort)
    end
  end

  describe 'standard field definitions' do
    it 'defines MTI field (0)' do
      field = described_class.get(0)
      
      expect(field.length_type).to eq(:fixed)
      expect(field.max_length).to eq(4)
      expect(field.data_type).to eq(:numeric)
    end

    it 'defines PAN field (2)' do
      field = described_class.get(2)
      
      expect(field.length_type).to eq(:llvar)
      expect(field.max_length).to eq(19)
      expect(field.data_type).to eq(:numeric)
    end

    it 'defines Processing Code field (3)' do
      field = described_class.get(3)
      
      expect(field.length_type).to eq(:fixed)
      expect(field.max_length).to eq(6)
      expect(field.data_type).to eq(:numeric)
    end

    it 'defines Amount field (4)' do
      field = described_class.get(4)
      
      expect(field.length_type).to eq(:fixed)
      expect(field.max_length).to eq(12)
      expect(field.data_type).to eq(:numeric)
    end

    it 'defines STAN field (11)' do
      field = described_class.get(11)
      
      expect(field.length_type).to eq(:fixed)
      expect(field.max_length).to eq(6)
      expect(field.data_type).to eq(:numeric)
    end

    it 'defines Response Code field (39)' do
      field = described_class.get(39)
      
      expect(field.length_type).to eq(:fixed)
      expect(field.max_length).to eq(2)
      expect(field.data_type).to eq(:alphanumeric)
    end

    it 'defines Card Acceptor Terminal ID field (41)' do
      field = described_class.get(41)
      
      expect(field.length_type).to eq(:fixed)
      expect(field.max_length).to eq(8)
      expect(field.data_type).to eq(:alphanumeric_special)
    end

    it 'defines ICC Data field (55)' do
      field = described_class.get(55)
      
      expect(field.length_type).to eq(:lllvar)
      expect(field.max_length).to eq(255)
      expect(field.data_type).to eq(:binary)
      expect(field.encoding).to eq(:binary)
    end

    it 'defines MAC field (128)' do
      field = described_class.get(128)
      
      expect(field.length_type).to eq(:fixed)
      expect(field.max_length).to eq(16)
      expect(field.data_type).to eq(:binary)
    end
  end

  describe 'field validation' do
    it 'validates PAN correctly' do
      field = described_class.get(2)
      
      expect { field.validate!("4111111111111111") }.not_to raise_error
      expect { field.validate!("411111111111111X") }.to raise_error(Iso8583::InvalidFormatError)
    end

    it 'validates amount correctly' do
      field = described_class.get(4)
      
      expect { field.validate!("000000012345") }.not_to raise_error
      expect { field.validate!("123") }.to raise_error(Iso8583::InvalidLengthError)
    end

    it 'validates response code correctly' do
      field = described_class.get(39)
      
      expect { field.validate!("00") }.not_to raise_error
      expect { field.validate!("ABC") }.to raise_error(Iso8583::InvalidLengthError)
    end
  end
end
