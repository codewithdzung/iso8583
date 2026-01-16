#!/usr/bin/env ruby
# frozen_string_literal: true

# Advanced usage examples for iso8583 gem

require 'bundler/setup'
require 'iso8583'

puts '=' * 60
puts 'ISO8583 Gem - Advanced Usage Examples'
puts '=' * 60
puts

# Example 1: Complete authorization flow
puts 'Example 1: Complete Authorization Flow'
puts '-' * 60

# Step 1: Create authorization request
auth_request = Iso8583::Message.new(mti: '0100')
auth_request[2] = '5200000000000001'
auth_request[3] = '000000'
auth_request[4] = '000000100000'
auth_request[7] = Time.now.strftime('%m%d%H%M%S')
auth_request[11] = rand(100_000..999_999).to_s.rjust(6, '0')
auth_request[14] = '2512'
auth_request[41] = 'TERM0001'
auth_request[49] = '840'

puts 'Authorization Request:'
puts auth_request.pretty_print
puts

# Step 2: Simulate sending over network
encoded_request = auth_request.encode
puts "Sending #{encoded_request.bytesize} bytes over network..."
puts

# Step 3: Simulate receiving and parsing
received_request = Iso8583::Message.parse(encoded_request)

# Step 4: Process and create response
auth_response = Iso8583::Message.new(mti: '0110')
auth_response[2] = received_request[2]
auth_response[3] = received_request[3]
auth_response[4] = received_request[4]
auth_response[7] = Time.now.strftime('%m%d%H%M%S')
auth_response[11] = received_request[11]
auth_response[38] = rand(100_000..999_999).to_s # 6-digit auth code
auth_response[39] = '00' # Approved

puts 'Authorization Response:'
puts auth_response.pretty_print
puts

# Example 2: Financial transaction with reversal
puts 'Example 2: Financial Transaction with Reversal'
puts '-' * 60

# Original transaction
original = Iso8583::Message.new(mti: '0200')
original[2] = '4111111111111111'
original[3] = '000000'
original[4] = '000000050000'
original[11] = '123456'
original[37] = (Time.now.to_i % 100_000_000).to_s.rjust(12, '0') # 12-digit RRN
original[41] = 'ATM00001'

puts 'Original Transaction:'
puts "  STAN: #{original[11]}"
puts "  RRN: #{original[37]}"
puts "  Amount: #{original[4]}"
puts

# Create reversal
reversal = Iso8583::Message.new(mti: '0400')
reversal[2] = original[2]
reversal[3] = original[3]
reversal[4] = original[4]
reversal[11] = (original[11].to_i + 1).to_s.rjust(6, '0') # New STAN
reversal[37] = original[37] # Original RRN
reversal[41] = original[41]

puts 'Reversal Transaction:'
puts "  Original STAN: #{original[11]}"
puts "  Reversal STAN: #{reversal[11]}"
puts "  Original RRN: #{reversal[37]}"
puts

# Example 3: Working with secondary bitmap
puts 'Example 3: Working with Secondary Bitmap (Fields > 64)'
puts '-' * 60

extended_message = Iso8583::Message.new(mti: '0200')
extended_message[2] = '4111111111111111'
extended_message[3] = '000000'
extended_message[4] = '000000012345'
extended_message[11] = '123456'

# Add fields in secondary bitmap range
extended_message[100] = '12345678901' # Receiving Institution ID (numeric)
extended_message[102] = 'ACC123456'
extended_message[103] = 'ACC654321'

puts 'Message with secondary bitmap:'
puts "  Primary bitmap fields: #{extended_message.field_numbers.select { |f| f <= 64 }.join(', ')}"
puts "  Secondary bitmap fields: #{extended_message.field_numbers.select { |f| f > 64 }.join(', ')}"
puts

encoded_extended = extended_message.encode
parsed_extended = Iso8583::Message.parse(encoded_extended)

puts 'After encoding/parsing:'
puts "  Field 100: #{parsed_extended[100]}"
puts "  Field 102: #{parsed_extended[102]}"
puts "  Field 103: #{parsed_extended[103]}"
puts

# Example 4: Network management
puts 'Example 4: Network Management Messages'
puts '-' * 60

# Sign-on request
signon = Iso8583::Message.new(mti: '0800')
signon[7] = Time.now.strftime('%m%d%H%M%S')
signon[11] = '000001'
signon[41] = 'TERM0001'

puts 'Sign-on Request (0800):'
puts "  Terminal: #{signon[41]}"
puts "  Time: #{signon[7]}"
puts

# Sign-on response
signon_response = Iso8583::Message.new(mti: '0810')
signon_response[7] = signon[7]
signon_response[11] = signon[11]
signon_response[39] = '00'
signon_response[41] = signon[41]

puts 'Sign-on Response (0810):'
puts "  Response Code: #{signon_response[39]}"
puts

# Example 5: Message cloning and modification
puts 'Example 5: Message Cloning and Modification'
puts '-' * 60

original_msg = Iso8583::Message.new(mti: '0200')
original_msg[2] = '4111111111111111'
original_msg[3] = '000000'
original_msg[4] = '000000100000'

# Clone and modify
cloned_msg = original_msg.clone
cloned_msg.mti = '0420' # Change to reversal advice
cloned_msg[11] = '654321'
cloned_msg[39] = '00'

puts "Original MTI: #{original_msg.mti}"
puts "Cloned MTI: #{cloned_msg.mti}"
puts "Original has field 11: #{original_msg.has_field?(11)}"
puts "Cloned has field 11: #{cloned_msg.has_field?(11)}"
puts

# Example 6: Converting to hash
puts 'Example 6: Converting Message to Hash'
puts '-' * 60

message = Iso8583::Message.new(mti: '0200')
message[2] = '4111111111111111'
message[3] = '000000'
message[4] = '000000050000'

hash = message.to_h
puts 'Message as hash:'
puts "  MTI: #{hash[:mti]}"
puts "  Fields: #{hash[:fields].inspect}"
puts

puts '=' * 60
puts 'Advanced examples completed successfully!'
puts '=' * 60
