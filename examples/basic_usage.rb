#!/usr/bin/env ruby
# frozen_string_literal: true

# Basic usage examples for iso8583 gem

require 'bundler/setup'
require 'iso8583'

puts '=' * 60
puts 'ISO8583 Gem - Basic Usage Examples'
puts '=' * 60
puts

# Example 1: Creating a simple message
puts 'Example 1: Creating a Simple Authorization Request'
puts '-' * 60

message = Iso8583::Message.new(mti: '0100')
message[2] = '5200000000000001' # Primary Account Number
message[3] = '000000'              # Processing Code
message[4] = '000000100000'        # Amount ($1000.00)
message[11] = '123456'             # System Trace Audit Number
message[49] = '840'                # Currency Code (USD)

puts message.pretty_print
puts

# Example 2: Encoding a message
puts 'Example 2: Encoding to Binary Format'
puts '-' * 60

encoded = message.encode
puts "Encoded message length: #{encoded.bytesize} bytes"
puts "Encoded message (hex): #{encoded.unpack1('H*')}"
puts

# Example 3: Parsing a message
puts 'Example 3: Parsing Binary Message'
puts '-' * 60

parsed = Iso8583::Message.parse(encoded)
puts "Parsed MTI: #{parsed.mti}"
puts "Parsed fields: #{parsed.field_numbers.join(', ')}"
puts "PAN: #{parsed[2]}"
puts "Amount: #{parsed[4]}"
puts

# Example 4: Field validation
puts 'Example 4: Field Validation'
puts '-' * 60

begin
  invalid_message = Iso8583::Message.new
  invalid_message[4] = '123' # Too short for amount field
rescue Iso8583::ValidationError => e
  puts "Validation error (expected): #{e.message}"
end
puts

# Example 5: Working with variable length fields
puts 'Example 5: Variable Length Fields'
puts '-' * 60

message2 = Iso8583::Message.new(mti: '0200')
message2[2] = '4111111111111111'   # 16-digit PAN
message2[32] = '12345'             # Short acquiring institution ID

puts "Field 2 (PAN): #{message2[2]} - Length: #{message2[2].length}"
puts "Field 32 (Acq ID): #{message2[32]} - Length: #{message2[32].length}"
puts

# Example 6: Creating a response message
puts 'Example 6: Creating Response Message'
puts '-' * 60

request = Iso8583::Message.new(mti: '0100')
request[2] = '5200000000000001'
request[3] = '000000'
request[4] = '000000050000'
request[11] = '654321'

# Create response by changing MTI and adding response fields
response = Iso8583::Message.new(mti: '0110')
response[2] = request[2]           # Echo PAN
response[3] = request[3]           # Echo processing code
response[4] = request[4]           # Echo amount
response[11] = request[11]         # Echo STAN
response[38] = '123456'            # Authorization ID (6 digits)
response[39] = '00'                # Response code (approved)

puts "Request MTI: #{request.mti}"
puts "Response MTI: #{response.mti}"
puts "Response code: #{response[39]}"
puts "Auth ID: #{response[38]}"
puts

puts '=' * 60
puts 'Examples completed successfully!'
puts '=' * 60
