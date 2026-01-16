# ISO8583 Examples

This directory contains examples demonstrating various features of the iso8583 gem.

## Running Examples

Make sure you have the gem installed:

```bash
bundle install
```

Then run any example:

```bash
ruby examples/basic_usage.rb
ruby examples/advanced_usage.rb
```

## Available Examples

### basic_usage.rb

Demonstrates fundamental operations:
- Creating messages
- Setting fields
- Encoding and parsing
- Field validation
- Variable length fields
- Request/response patterns

### advanced_usage.rb

Shows advanced features:
- Complete authorization flows
- Financial transactions with reversals
- Secondary bitmap handling
- Network management messages
- Message cloning
- Converting to hash

## Common Use Cases

### Authorization Request

```ruby
message = Iso8583::Message.new(mti: "0100")
message[2] = "5200000000000001"   # PAN
message[3] = "000000"              # Processing Code
message[4] = "000000100000"        # Amount
message[11] = "123456"             # STAN
message[49] = "840"                # Currency

encoded = message.encode
```

### Parsing Response

```ruby
parsed = Iso8583::Message.parse(binary_data)
if parsed[39] == "00"
  puts "Transaction approved!"
  puts "Auth code: #{parsed[38]}"
end
```

### Error Handling

```ruby
begin
  message[4] = "invalid"
rescue Iso8583::ValidationError => e
  puts "Validation failed: #{e.message}"
end
```

## Field Reference

Common fields used in examples:

- **Field 2**: Primary Account Number (PAN)
- **Field 3**: Processing Code
- **Field 4**: Amount, Transaction
- **Field 7**: Transmission Date & Time
- **Field 11**: System Trace Audit Number (STAN)
- **Field 37**: Retrieval Reference Number (RRN)
- **Field 38**: Authorization ID Response
- **Field 39**: Response Code
- **Field 41**: Card Acceptor Terminal ID
- **Field 49**: Currency Code

## Response Codes

Common response codes:

- **00**: Approved
- **01**: Refer to card issuer
- **05**: Do not honor
- **12**: Invalid transaction
- **51**: Insufficient funds
- **54**: Expired card

## MTI (Message Type Indicator)

Common MTI values:

- **0100**: Authorization Request
- **0110**: Authorization Response
- **0200**: Financial Transaction Request
- **0210**: Financial Transaction Response
- **0400**: Reversal Request
- **0410**: Reversal Response
- **0800**: Network Management Request
- **0810**: Network Management Response

## Additional Resources

- [ISO 8583 Wikipedia](https://en.wikipedia.org/wiki/ISO_8583)
- [Main README](../README.md)
- [API Documentation](../README.md#usage)
