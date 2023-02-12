# Lighstorm

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
- [Development](#development)
  - [Generating Documentation](#generating-documentation)
  - [Publish to RubyGems](#publish-to-rubygems)

## About

_Lighstorm_ is an opinionated abstraction layer on top of the [lnd-client](https://github.com/icebaker/lnd-client).

It brings an [object-oriented](https://en.wikipedia.org/wiki/Object-oriented_programming) approach for interacting with a [Lightning Node](https://github.com/lightningnetwork/lnd), influenced by the [Active Record Pattern](https://www.martinfowler.com/eaaCatalog/activeRecord.html) and [Active Record Models](https://guides.rubyonrails.org/active_record_basics.html) conventions.

Although it tries to stay close to [Lightning's terminologies](https://docs.lightning.engineering/lightning-network-tools/lnd), it brings its own vocabulary and [data modeling](https://icebaker.github.io/lighstorm/#/README?id=data-modeling), optimizing for [programmer happiness](https://rubyonrails.org/doctrine).

## Usage

Add to your `Gemfile`:

```ruby
gem 'lighstorm', '~> 0.0.3'
```

```ruby
require 'lighstorm'

Lighstorm.config!(
  lnd_address: '127.0.0.1:10009',
  certificate_path: '/lnd/tls.cert',
  macaroon_path: '/lnd/data/chain/bitcoin/mainnet/admin.macaroon',
)

puts Lighstorm.version # => 0.0.3

Lighstorm::Satoshis.new(
  milisatoshis: 75_621_650
).satoshis # => 75_621

Lighstorm::Node.myself.alias # => icebaker/old-stone
```

Check the [full documentation](https://icebaker.github.io/lighstorm).

## Development

```ruby
# Gemfile
gem 'lighstorm', path: '/home/user/lighstorm'

# demo.rb
require 'lighstorm'

puts Lighstorm.version # => 0.0.3
```

```sh
bundle
rubocop -A
```

### Generating Documentation

```sh
npm i docsify-cli -g

docsify serve ./docs
```

### Publish to RubyGems

```sh
gem build lighstorm.gemspec

gem signin

gem push lighstorm-0.0.3.gem
```
