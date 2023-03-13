# Lighstorm [![Gem Version](https://badge.fury.io/rb/lighstorm.svg)](https://badge.fury.io/rb/lighstorm) ![RSpec Tests Status](https://github.com/icebaker/lighstorm/actions/workflows/ruby-rspec-tests.yml/badge.svg)

> ⚠️ Warning: Early-stage, breaking changes are expected.

API for interacting with a [Lightning Node](https://lightning.network).

![Lighstorm text written stylized with an illustration of a Graph connecting two Nodes.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/lighstorm.png)

```ruby
Lighstorm::Channel.mine.first.myself.node.alias
```

## Index

- [About](#about)
- [Usage](#usage)
  - [Documentation](https://icebaker.github.io/lighstorm)
  - [Tutorials and Articles](#tutorials-and-articles)
- [Development](https://icebaker.github.io/lighstorm/#/README?id=development)

## About

_Lighstorm_ is an opinionated abstraction layer on top of the [lnd-client](https://github.com/icebaker/lnd-client).

It brings an [_object-oriented_](https://en.wikipedia.org/wiki/Object-oriented_programming) approach for interacting with a [Lightning Node](https://github.com/lightningnetwork/lnd), influenced by the [Active Record Pattern](https://www.martinfowler.com/eaaCatalog/activeRecord.html) and [Active Record Models](https://guides.rubyonrails.org/active_record_basics.html) conventions.

However, despite the fluidity of _Object Orientation_ being desired in its public interface, internally, most of its code is structured following the [_Hexagonal Architecture_](https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)) and [_Functional Programming_](https://en.wikipedia.org/wiki/Functional_programming) principles.

It aims to be intuitive to use while being highly **reliable**, as it deals with people's money, and easily testable since its [tests](https://icebaker.github.io/lighstorm/#/README?id=testing) are the foundation for its reliability.

Although it tries to stay close to [Lightning's terminologies](https://docs.lightning.engineering/the-lightning-network/overview), it brings its own vocabulary and [data modeling](https://icebaker.github.io/lighstorm/#/README?id=data-modeling), optimizing for [programmer happiness](https://rubyonrails.org/doctrine#optimize-for-programmer-happiness).

## Usage

Add to your `Gemfile`:

```ruby
gem 'lighstorm', '~> 0.0.11'
```

```ruby
require 'lighstorm'

Lighstorm.config!(
  lnd_address: '127.0.0.1:10009',
  certificate_path: '/lnd/tls.cert',
  macaroon_path: '/lnd/data/chain/bitcoin/mainnet/admin.macaroon',
)

puts Lighstorm.version # => 0.0.11

Lighstorm::Node.myself.alias # => icebaker/old-stone

Lighstorm::Invoice.create(
  description: 'Coffee',
  amount: { millisatoshis: 1_000 },
  payable: 'once'
)

Lighstorm::Invoice.decode('lnbc20m1pv...qqdhhwkj').pay

Lighstorm::Invoice.decode('lnbc20m1pv...qqdhhwkj').pay(
  fee: { maximum: { millisatoshis: 1000 } }
)

Lighstorm::Satoshis.new(
  millisatoshis: 75_621_650
).satoshis # => 75_621
```

Check the [full documentation](https://icebaker.github.io/lighstorm).

## Tutorials and Articles

- [Getting Started with Lightning Payments in Ruby](https://mirror.xyz/icebaker.eth/4RUF8umW_KRfVWHHvC2jz0c7YJqzv3RUUvLN-Mln5IU)

## Development

Check the [development documentation](https://icebaker.github.io/lighstorm/#/README?id=development).
