# frozen_string_literal: true

RSpec.describe Iso8583 do
  it 'has a version number' do
    expect(Iso8583::VERSION).not_to be nil
  end

  describe 'integration tests' do
    it 'handles complete authorization flow' do
      # Create authorization request
      request = Iso8583::Message.new(mti: '0100')
      request[2] = '5200000000000001' # PAN
      request[3] = '000000'              # Processing Code - Purchase
      request[4] = '000000100000'        # Amount - $1000.00
      request[7] = '0625153540'          # Transmission Date/Time
      request[11] = '123456'             # STAN
      request[14] = '2512'               # Card Expiration Date
      request[18] = '5999'               # Merchant Type - Restaurant
      request[22] = '051'                # POS Entry Mode
      request[25] = '00'                 # POS Condition Code
      request[41] = 'TERMID01'           # Terminal ID
      request[42] = 'MERCHANT0001234'    # Merchant ID
      request[49] = '840'                # Currency Code - USD

      # Encode request
      encoded_request = request.encode
      expect(encoded_request).to be_a(String)
      expect(encoded_request.bytesize).to be > 0

      # Simulate network transmission and parsing
      parsed_request = Iso8583::Message.parse(encoded_request)
      expect(parsed_request.mti).to eq('0100')
      expect(parsed_request[2]).to eq('5200000000000001')
      expect(parsed_request[4]).to eq('000000100000')

      # Create authorization response
      response = Iso8583::Message.new(mti: '0110')
      response[2] = parsed_request[2]    # Echo PAN
      response[3] = parsed_request[3]    # Echo Processing Code
      response[4] = parsed_request[4]    # Echo Amount
      response[7] = '0625153545'         # Response Time
      response[11] = parsed_request[11]  # Echo STAN
      response[38] = 'AUTH01'            # Authorization Code
      response[39] = '00'                # Response Code - Approved
      response[41] = parsed_request[41]  # Echo Terminal ID

      # Encode and parse response
      encoded_response = response.encode
      parsed_response = Iso8583::Message.parse(encoded_response)

      expect(parsed_response.mti).to eq('0110')
      expect(parsed_response[39]).to eq('00')
      expect(parsed_response[38]).to eq('AUTH01')
    end

    it 'handles financial transaction with reversal' do
      # Original financial transaction
      original = Iso8583::Message.new(mti: '0200')
      original[2] = '4111111111111111'
      original[3] = '000000'
      original[4] = '000000050000'
      original[7] = '0625120000'
      original[11] = '654321'
      original[37] = '123456789012' # RRN
      original[41] = 'ATM00001'
      original[49] = '840'

      encoded = original.encode
      parsed = Iso8583::Message.parse(encoded)

      # Verify parsing
      expect(parsed).to eq(original)

      # Create reversal
      reversal = Iso8583::Message.new(mti: '0400')
      reversal[2] = original[2]
      reversal[3] = original[3]
      reversal[4] = original[4]
      reversal[11] = '654322'            # New STAN
      reversal[37] = original[37]        # Original RRN
      # Field 90 must be 42 chars: MTI(4) + STAN(6) + DateTime(10) + padding(22)
      reversal[90] = "0200#{original[11]}#{original[7]}0000000000000000000000" # 4+6+10+22=42 chars

      reversal_encoded = reversal.encode
      reversal_parsed = Iso8583::Message.parse(reversal_encoded)

      expect(reversal_parsed.mti).to eq('0400')
      expect(reversal_parsed[90]).to include(original[11])
    end

    it 'handles messages with secondary bitmap' do
      message = Iso8583::Message.new(mti: '0200')

      # Primary bitmap fields
      message[2] = '4111111111111111'
      message[3] = '000000'
      message[4] = '000000012345'
      message[11] = '123456'

      # Secondary bitmap fields
      message[100] = '12345'
      message[102] = 'ACCOUNT123'
      message[103] = 'ACCOUNT456'

      encoded = message.encode

      # Verify secondary bitmap is present
      # MTI (4) + Primary Bitmap (8) + Secondary Bitmap (8) + data
      expect(encoded.bytesize).to be >= 20

      parsed = Iso8583::Message.parse(encoded)

      expect(parsed.field_numbers).to include(100, 102, 103)
      expect(parsed[100]).to eq('12345')
      expect(parsed[102]).to eq('ACCOUNT123')
      expect(parsed[103]).to eq('ACCOUNT456')
    end

    it 'handles network management messages' do
      # Sign-on request
      signon = Iso8583::Message.new(mti: '0800')
      signon[7] = '0625123456'
      signon[11] = '000001'
      signon[41] = 'TERMINAL'

      encoded = signon.encode
      parsed = Iso8583::Message.parse(encoded)

      expect(parsed.mti).to eq('0800')

      # Sign-on response
      response = Iso8583::Message.new(mti: '0810')
      response[7] = parsed[7]
      response[11] = parsed[11]
      response[39] = '00'
      response[41] = parsed[41]

      encoded_response = response.encode
      parsed_response = Iso8583::Message.parse(encoded_response)

      expect(parsed_response[39]).to eq('00')
    end

    it 'preserves data through multiple encode/decode cycles' do
      original = Iso8583::Message.new(mti: '0200')
      original[2] = '4111111111111111'
      original[3] = '000000'
      original[4] = '000000123456'
      original[7] = '0625153540'
      original[11] = '123456'
      original[39] = '00'
      original[41] = 'TERM0001'

      # First cycle
      encoded1 = original.encode
      parsed1 = Iso8583::Message.parse(encoded1)

      # Second cycle
      encoded2 = parsed1.encode
      parsed2 = Iso8583::Message.parse(encoded2)

      # Third cycle
      encoded3 = parsed2.encode
      parsed3 = Iso8583::Message.parse(encoded3)

      expect(parsed3).to eq(original)
      expect(encoded1).to eq(encoded2)
      expect(encoded2).to eq(encoded3)
    end

    it 'handles real-world ATM withdrawal' do
      message = Iso8583::Message.new(mti: '0200')
      message[2] = '5200000000000001'
      message[3] = '010000'              # Withdrawal from savings
      message[4] = '000000020000'        # $200.00
      message[7] = '0625153540'
      message[11] = '123456'
      message[12] = '153540'             # Local time
      message[13] = '0625'               # Local date
      message[18] = '6011'               # ATM merchant type
      message[22] = '021'                # POS entry mode - Magnetic stripe
      message[25] = '00'                 # POS condition
      message[32] = '12345'              # Acquiring institution
      message[37] = '123456789012'       # RRN
      message[41] = 'ATM12345'
      message[42] = 'LOCATION0000001'    # 15 chars
      message[49] = '840'

      encoded = message.encode
      parsed = Iso8583::Message.parse(encoded)

      expect(parsed.mti).to eq('0200')
      expect(parsed.field_numbers.length).to be >= 13 # At least 13 fields
      expect(parsed[3]).to eq('010000')
      expect(parsed[4]).to eq('000000020000')
    end
  end

  describe 'library features' do
    it 'provides debug mode' do
      expect(Iso8583).to respond_to(:debug)
      expect(Iso8583).to respond_to(:debug=)
    end

    it 'provides version information' do
      expect(Iso8583.version).to eq(Iso8583::VERSION)
    end
  end
end
