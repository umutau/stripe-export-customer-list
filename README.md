# README

## Chart-Mogul Code Challenge

### USAGE: 
Add module into your file:

```
include PaymentSystems
```
run the following command:
```
PaymentSystems::StripeAdapter::Commands::ExportCustomers.execute
```

### REQUIREMENTS:
- gem 'stripe'
- gem 'stripe-ruby-mock'
- add following code into credentials
```
STRIPE_API_KEY: sk_test_RsUIbMyxLQszELZQEXHTeFA9008YRV7Vhr
```