# ISO8583 - Modern Ruby Financial Messaging Library

[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.1.0-ruby.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

A modern, clean, and well-tested Ruby implementation of the ISO 8583 financial messaging protocol. This library provides a robust framework for parsing, building, and validating ISO 8583 messages commonly used in payment card systems, ATM transactions, and financial networks.

## Features

- 🎯 **Clean API** - Intuitive and easy-to-use interface
- 📦 **Multiple Encoding Formats** - Support for ASCII, BCD, and Binary encoding
- ✅ **Validation** - Built-in field validation and type checking
- 🔒 **Type Safety** - Strong typing for field definitions
- 📝 **Comprehensive Tests** - Full test coverage
- 🚀 **Performance** - Optimized for speed and memory efficiency
- 📚 **Well Documented** - Clear examples and API documentation

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'iso8583'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install iso8583
```

## Quick Start

```ruby
require 'iso8583'

# Create a new ISO 8583 message
message = Iso8583::Message.new

# Set message type
message.mti = "0200"

# Set fields
message[2] = "4111111111111111"  # Primary Account Number
message[3] = "000000"             # Processing Code
message[4] = "000000010000"       # Transaction Amount
message[7] = "0110153540"         # Transmission Date & Time

# Encode the message
encoded = message.encode

# Parse a message
parsed = Iso8583::Message.parse(encoded)
puts parsed[2]  # => "4111111111111111"
```

## Usage

### Creating Messages

```ruby
# Create a new authorization request
message = Iso8583::Message.new(mti: "0100")

# Set fields using field numbers
message[2] = "5200000000000001"   # PAN
message[3] = "000000"              # Processing Code
message[4] = "000000050000"        # Amount
message[11] = "123456"             # STAN (System Trace Audit Number)
message[41] = "TERMINAL001"        # Card Acceptor Terminal ID
message[49] = "840"                # Currency Code (USD)
```

### Parsing Messages

```ruby
# Parse from binary or ASCII format
raw_message = "..." # Your ISO 8583 message bytes
message = Iso8583::Message.parse(raw_message)

# Access fields
pan = message[2]
amount = message[4]
stan = message[11]

# Check if field is present
if message.has_field?(39)
  response_code = message[39]
end
```

### Field Validation

```ruby
message = Iso8583::Message.new

# Automatic validation
begin
  message[4] = "123"  # Too short for amount field
rescue Iso8583::ValidationError => e
  puts e.message
end
```

## ISO 8583 Basics

ISO 8583 is an international standard for financial transaction card originated messages. A message consists of:

1. **MTI (Message Type Indicator)** - 4 digits indicating the message type
2. **Bitmap** - Indicates which fields are present in the message
3. **Data Fields** - The actual transaction data (up to 128 fields)

### Message Type Indicator (MTI)

The MTI is a 4-digit numeric field:
- First digit: Version (0 = ISO 8583:1987, 1 = ISO 8583:1993, 2 = ISO 8583:2003)
- Second digit: Message class (0 = Reserved, 1 = Authorization, 2 = Financial, etc.)
- Third digit: Message function (0 = Request, 1 = Response, etc.)
- Fourth digit: Message origin (0 = Acquirer, 1 = Issuer, etc.)

Common MTI values:
- `0100` - Authorization Request
- `0110` - Authorization Response
- `0200` - Financial Transaction Request
- `0210` - Financial Transaction Response
- `0800` - Network Management Request
- `0810` - Network Management Response

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`.

## Testing

```bash
bundle exec rake spec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/codewithdzung/iso8583.


## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Acknowledgments

This library implements the ISO 8583 standard for financial transaction card originated messages. Special thanks to the financial technology community for their valuable insights.

## Author

**Nguyen Tien Dzung**
- Email: imnguyentiendzung@gmail.com
- GitHub: [@codewithdzung](https://github.com/codewithdzung)


