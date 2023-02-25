> ⚠️ Warning: Early-stage project, breaking changes are expected.

# About

> Lighstorm: API for interacting with a [Lightning Node](https://lightning.network).

_Lighstorm_ is an opinionated abstraction layer on top of the [lnd-client](https://github.com/icebaker/lnd-client).

It brings an [object-oriented](https://en.wikipedia.org/wiki/Object-oriented_programming) approach for interacting with a [Lightning Node](https://github.com/lightningnetwork/lnd), influenced by the [Active Record Pattern](https://www.martinfowler.com/eaaCatalog/activeRecord.html) and [Active Record Models](https://guides.rubyonrails.org/active_record_basics.html) conventions.

Although it tries to stay close to [Lightning's terminologies](https://docs.lightning.engineering/lightning-network-tools/lnd), it brings its own vocabulary and [data modeling](#data-modeling), optimizing for [programmer happiness](https://rubyonrails.org/doctrine).

# Getting Started

![Lighstorm text written stylized with an illustration of a Graph connecting two Nodes.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/lighstorm.png)

```ruby
Lighstorm::Channel.mine.first.myself.node.alias
```

## Installing

Add to your `Gemfile`:

```ruby
gem 'lighstorm', '~> 0.0.6'
```

Run `bundle install`.

## Credentials

Set the following _Environment Variables_ or create a `.env` file:
```bash
LIGHSTORM_LND_ADDRESS=127.0.0.1:10009
LIGHSTORM_CERTIFICATE_PATH=/lnd/tls.cert
LIGHSTORM_MACAROON_PATH=/lnd/data/chain/bitcoin/mainnet/admin.macaroon
```

It will automatically load your credentials.

Alternatively, you can set the credentials at runtime:

```ruby
require 'lighstorm'

Lighstorm.config!(
  lnd_address: '127.0.0.1:10009',
  certificate_path: '/lnd/tls.cert',
  macaroon_path: '/lnd/data/chain/bitcoin/mainnet/admin.macaroon',
)

```

## Examples
```ruby
require 'lighstorm'

puts Lighstorm.version # => 0.0.6

Lighstorm::Satoshis.new(
  milisatoshis: 75_621_650
).satoshis # => 75_621

Lighstorm::Node.myself.alias # => icebaker/old-stone
Lighstorm::Node.myself.public_key # => 02d3...e997

Lighstorm::Node.myself.to_h #> { ... }

Lighstorm::Node.myself.channels.count # => 5

Lighstorm::Channel.mine.first.partner.node.alias

forward = Lighstorm::Forward.all(limit: 10).first

forward.in.amount.milisatoshis # => 75621650
forward.in.amount.satoshis # => 75621
forward.in.amount.bitcoins # => 0.0007562165
forward.in.channel.partner.node.alias
forward.out.channel.partner.node.alias

forward.to_h # => { ... }

payment = Lighstorm::Payment.all.first

payment.from.channel.id # => 850099509773795329
payment.to.channel.id # => 821539695188246532
payment.amount.sats # => 957262
payment.hops.size # => 4
payment.hops.first.channel.partner.node.alias
```

# Data Modeling

## Graph Theory

[Graphs](https://en.wikipedia.org/wiki/Graph_theory) provide a great representation to abstract the [Lightning Network](https://lightning.network) data.

So, we are going to think in terms of _Edges_, _Nodes_, and _Connections_:

[![This is an image describing Graphs and their terminologies.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-theory.png)](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-theory.png)
<center style="margin-top: -1.4em;">
  <a href="https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-theory.png" rel="noopener noreferrer" target="_blank">
    click to zoom
  </a>
</center>

## Channel

```ruby
channel = Lighstorm::Channel.mine.first

channel.id

channel.accounting.capacity.milisatoshis

channel.partner.accounting.balance.milisatoshis
channel.partner.node.alias
channel.partner.policy.fee.rate.parts_per_million

channel.myself.accounting.balance.milisatoshis
channel.myself.node.alias
channel.myself.policy.fee.rate.parts_per_million
```

[![This is an image representing Channel as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-channel.png)](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-channel.png)
<center style="margin-top: -1.4em;">
  <a href="https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-channel.png" rel="noopener noreferrer" target="_blank">
    click to zoom
  </a>
</center>

## Forward

```ruby
forward = Lighstorm::Forward.last

forward.at

forward.fee.milisatoshis
forward.fee.parts_per_million

forward.in.amount.milisatoshis
forward.out.amount.milisatoshis

forward.in.channel.id
forward.in.channel.partner.node.alias

forward.out.channel.id
forward.out.channel.partner.node.alias
```

[![This is an image representing Forward as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-forward.png)](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-forward.png)
<center style="margin-top: -1.4em;">
  <a href="https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-forward.png" rel="noopener noreferrer" target="_blank">
    click to zoom
  </a>
</center>

## Payment

```ruby
payment = Payment.last

payment.status
payment.created_at

# https://github.com/lightning/bolts/blob/master/11-payment-encoding.md
payment.request.code # "lnbc20m1pv...qqdhhwkj"

payment.request.amount.milisatoshis

payment.from.hop
payment.from.amount.milisatoshis
payment.from.fee.milisatoshis
payment.from.channel.id
payment.from.channel.target.alias
payment.from.channel.exit.alias

payment.to.hop
payment.to.amount.milisatoshis
payment.to.fee.milisatoshis
payment.to.channel.id
payment.to.channel.target.alias

payment.hops[0].hop
payment.hops[0].amount.milisatoshis
payment.hops[0].fee.milisatoshis
payment.hops[0].channel.id
payment.hops[0].channel.target.alias
```

[![This is an image representing Payment as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-payment.png)](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-payment.png)
<center style="margin-top: -1.4em;">
  <a href="https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-payment.png" rel="noopener noreferrer" target="_blank">
    click to zoom
  </a>
</center>

# Error Handling

## Rescuing
```ruby
require 'lighstorm'

channel = Lighstorm::Channel.mine.first

begin
  channel.myself.policy.fee.update(
    { rate: { parts_per_million: -1 } }, preview: true
  )
rescue Lighstorm::Errors::NegativeNotAllowedError => error
  puts error.message # 'fee rate can't be negative: -1'
end

begin
  channel.myself.policy.fee.update(
    { rate: { parts_per_million: -1 } }, preview: true
  )
rescue Lighstorm::Errors::LighstormError => error
  puts error.message # 'fee rate can't be negative: -1'
end
```

### For Short

```ruby
require 'lighstorm'
require 'lighstorm/errors'

channel = Lighstorm::Channel.mine.first

begin
  channel.myself.policy.fee.update(
    { rate: { parts_per_million: -1 } }, preview: true
  )
rescue NegativeNotAllowedError => error
  puts error.message # "fee rate can't be negative: -1"
end

begin
  channel.myself.policy.fee.update(
    { rate: { parts_per_million: -1 } }, preview: true
  )
rescue LighstormError => error
  puts error.message # "fee rate can't be negative: -1"
end
```

## Errors
```ruby
LighstormError

IncoherentGossipError

TooManyArgumentsError
MissingCredentialsError
MissingGossipHandlerError
MissingMilisatoshisError
MissingPartsPerMillionError
MissingTTLError

NegativeNotAllowedError

NotYourChannelError
NotYourNodeError
UnknownChannelError

OperationNotAllowedError
UnexpectedNumberOfHTLCsError
UpdateChannelPolicyError
```

# API

## Node
```ruby
Lighstorm::Node

Lighstorm::Node.myself # Your Node.
Lighstorm::Node.all # All 18k+ Nodes on the Network.
Lighstorm::Node.all(limit: 10)
Lighstorm::Node.find_by_public_key(
  '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'
)

# _key is helpful for reactive javascript frameworks.
# Please don't consider it as a unique identifier
# for the item. Instead, use it as a volatile key for
# the item's current state that may change at any moment.
node._key

node.to_h

node.channels

node.alias
node.public_key
node.color
node.myself?

node.platform.blockchain
node.platform.network
node.platform.lightning.implementation
node.platform.lightning.version
```

## Channel

[![This is an image representing Channel as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-channel.png)](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-channel.png)
<center style="margin-top: -1.4em;">
  <a href="https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-channel.png" rel="noopener noreferrer" target="_blank">
    click to zoom
  </a>
</center>

```ruby
Lighstorm::Channel
Lighstorm::Channel.mine # Your Node's Channels.
Lighstorm::Channel.all # All 80k+ Channels on the Network.
Lighstorm::Channel.all(limit: 10)
Lighstorm::Channel.find_by_id('850099509773795329')

# _key is helpful for reactive javascript frameworks.
# Please don't consider it as a unique identifier
# for the item. Instead, use it as a volatile key for
# the item's current state that may change at any moment.
channel._key 

channel.to_h

channel.mine?

channel.id
channel.opened_at
channel.up_at
channel.state
channel.active?
channel.exposure

channel.accounting.capacity.milisatoshis
channel.accounting.sent.milisatoshis
channel.accounting.received.milisatoshis
channel.accounting.unsettled.milisatoshis

# Channels that don't belong to you:
channel.partners

channel.partners[0]
channel.partners[0].node.alias

channel.partners[1]
channel.partners[1].node.alias

# Channels that belong to you:
channel.transaction.funding.id
channel.transaction.funding.index

channel.partner
channel.partner.state
channel.partner.active?

channel.partner.node.public_key
channel.partner.node.alias
channel.partner.node.color

channel.partner.accounting.balance.milisatoshis

channel.partner.policy.fee.base.milisatoshis
channel.partner.policy.fee.rate.parts_per_million

channel.partner.policy.htlc.minimum.milisatoshis
channel.partner.policy.htlc.maximum.milisatoshis
channel.partner.policy.htlc.blocks.delta.minimum

channel.myself
channel.myself.state
channel.myself.active?

channel.myself.node.public_key
channel.myself.node.alias
channel.myself.node.color

channel.myself.accounting.balance.milisatoshis

channel.myself.policy.fee.base.milisatoshis
channel.myself.policy.fee.rate.parts_per_million

channel.myself.policy.htlc.minimum.milisatoshis
channel.myself.policy.htlc.maximum.milisatoshis
channel.myself.policy.htlc.blocks.delta.minimum
```

### Operations

```ruby
channel = Lighstorm::Channel.mine.first

# 'preview' let you check the expected operation
# before actually performing it for debug purposes
channel.myself.policy.fee.update(
  { rate: { parts_per_million: 25 } }, preview: true
)

channel.myself.policy.fee.update(
  { base: { milisatoshis: 1 } }
)

channel.myself.policy.fee.update(
  { rate: { parts_per_million: 25 } }
)

channel.myself.policy.fee.update(
  { base: { milisatoshis: 1 }, rate: { parts_per_million: 25 } }
)
```

## Invoice

[Understanding Lightning Invoices](https://docs.lightning.engineering/the-lightning-network/payment-lifecycle/understanding-lightning-invoices)

```ruby
Lighstorm::Invoice
Lighstorm::Invoice.all
Lighstorm::Invoice.all(limit: 10)
Lighstorm::Invoice.first
Lighstorm::Invoice.last

Lighstorm::Invoice.find_by_secret_hash(
  '1d438b8100518c9fba0a607e3317d6b36f74ceef3a6591836eb2f679c6853501'
)

# _key is helpful for reactive javascript frameworks.
# Please don't consider it as a unique identifier
# for the item. Instead, use it as a volatile key for
# the item's current state that may change at any moment.
invoice._key

invoice.created_at
invoice.settle_at

invoice.state

# https://github.com/lightning/bolts/blob/master/11-payment-encoding.md
invoice.request.code # "lnbc20m1pv...qqdhhwkj"

invoice.request.amount.milisatoshis

invoice.request.description.memo
invoice.request.description.hash

# https://docs.lightning.engineering/the-lightning-network/multihop-payments
invoice.request.secret.preimage
invoice.request.secret.hash

invoice.request.address
```

### Operations

[Understanding Lightning Invoices](https://docs.lightning.engineering/the-lightning-network/payment-lifecycle/understanding-lightning-invoices)

```ruby
# 'preview' let you check the expected operation
# before actually performing it for debug purposes
invoice = Lighstorm::Invoice.create(
  milisatoshis: 1000, description: 'Coffee', preview: true
)

invoice = Lighstorm::Invoice.create(
  milisatoshis: 1000, description: 'Piña Colada'
)
```

## Payment

[![This is an image representing Payment as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-payment.png)](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-payment.png)
<center style="margin-top: -1.4em;">
  <a href="https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-payment.png" rel="noopener noreferrer" target="_blank">
    click to zoom
  </a>
</center>

```ruby
Lighstorm::Payment
Lighstorm::Payment.all
Lighstorm::Payment.first
Lighstorm::Payment.last
Lighstorm::Payment.all(limit: 10, purpose: 'rebalance')

# Possible Purposes:
['self-payment', 'peer-to-peer', 'rebalance', 'payment']

# _key is helpful for reactive javascript frameworks.
# Please don't consider it as a unique identifier
# for the item. Instead, use it as a volatile key for
# the item's current state that may change at any moment.
payment._key

payment.to_h

payment.status
payment.created_at
payment.settled_at
payment.purpose

payment.fee.milisatoshis
payment.fee.parts_per_million(
  payment.request.amount.milisatoshis
)

# https://github.com/lightning/bolts/blob/master/11-payment-encoding.md
payment.request.code # "lnbc20m1pv...qqdhhwkj"

payment.request.amount.milisatoshis

# https://docs.lightning.engineering/the-lightning-network/multihop-payments
payment.request.secret.preimage
payment.request.secret.hash

payment.request.address

payment.request.description.memo
payment.request.description.hash

payment.from.hop
payment.from.amount.milisatoshis
payment.from.fee.milisatoshis
payment.from.fee.parts_per_million(payment.from.amount.milisatoshis)

payment.from.channel.id

payment.from.channel.target.public_key
payment.from.channel.target.alias
payment.from.channel.target.color

payment.from.channel.exit.public_key
payment.from.channel.exit.alias
payment.from.channel.exit.color

payment.to.hop
payment.to.amount.milisatoshis
payment.to.fee.milisatoshis
payment.to.fee.parts_per_million(payment.to.amount.milisatoshis)

payment.to.channel.id

payment.to.channel.target.public_key
payment.to.channel.target.alias
payment.to.channel.target.color

payment.to.channel.entry.public_key
payment.to.channel.entry.alias
payment.to.channel.entry.color

payment.hops.size

payment.hops[0].first?
payment.hops[0].last?

payment.hops[0].hop
payment.hops[0].amount.milisatoshis
payment.hops[0].fee.milisatoshis
payment.hops[0].fee.parts_per_million(payment.hops[0].amount.milisatoshis)

payment.hops[0].channel.id

payment.hops[0].channel.target.public_key
payment.hops[0].channel.target.alias
payment.hops[0].channel.target.color

payment.hops[0].channel.entry.public_key
payment.hops[0].channel.entry.alias
payment.hops[0].channel.entry.color
```
### Performance
Avoid fetching data that you don't need:
```ruby
Lighstorm::Payment.all(
  fetch: {
    get_node_info: false,
    lookup_invoice: false,
    decode_pay_req: false,
    get_chan_info: false }
)
```

## Forward

[![This is an image representing Forward as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-forward.png)](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-forward.png)
<center style="margin-top: -1.4em;">
  <a href="https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-forward.png" rel="noopener noreferrer" target="_blank">
    click to zoom
  </a>
</center>

```ruby
Lighstorm::Forward
Lighstorm::Forward.all
Lighstorm::Forward.first
Lighstorm::Forward.last
Lighstorm::Forward.all(limit: 10)

forward.to_h

# _key is helpful for reactive javascript frameworks.
# Please don't consider it as a unique identifier
# for the item. Instead, use it as a volatile key for
# the item's current state that may change at any moment.
forward._key

forward.at

forward.fee.milisatoshis
forward.fee.parts_per_million(
  forward.in.amount.milisatoshis
)

forward.in.amount.milisatoshis

forward.in.channel.id
forward.in.channel.partner.node.alias
forward.in.channel.partner.node.public_key
forward.in.channel.partner.node.color

forward.out.amount.milisatoshis

forward.out.channel.id
forward.out.channel.partner.node.alias
forward.out.channel.partner.node.public_key
forward.out.channel.partner.node.color
```

### Grouping

```ruby
Lighstorm::Forward.group_by_channel(direction: :in, hours_ago: 24, limit: 5)

group.to_h

# _key is helpful for reactive javascript frameworks.
# Please don't consider it as a unique identifier
# for the item. Instead, use it as a volatile key for
# the item's current state that may change at any moment.
group._key

group.last_at
group.analysis.count
group.analysis.sums.amount.milisatoshis
group.analysis.sums.fee.milisatoshis
group.analysis.averages.amount.milisatoshis
group.analysis.averages.fee.milisatoshis
group.analysis.averages.fee.parts_per_million(
  group.analysis.averages.amount.milisatoshis
)

group.channel.id
group.channel.partner.node.alias
group.channel.partner.node.public_key
group.channel.partner.node.color

Lighstorm::Forward.group_by_channel(direction: :out)

group.to_h

group.last_at
group.analysis.count

group.channel.id
group.channel.partner.node.alias
group.channel.partner.node.public_key
group.channel.partner.node.color
```

## Gossip

[The Gossip Network](https://docs.lightning.engineering/the-lightning-network/the-gossip-network)

### Node

```ruby
gossip = {
  'identityKey' => '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997',
  'alias' => 'icebaker',
  'color' => '#eb34a4'
}

Lighstorm::Node.adapt(gossip: gossip)

node = Lighstorm::Node.find_by_public_key(
  '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'
)

diff = node.apply!(gossip: gossip)

Lighstorm::Node.adapt(dump: node.dump)
```

### Channel

```ruby
gossip = {
  'chanId' => '850099509773795329',
  'capacity' => '5000000',
  'routingPolicy' => {
    'timeLockDelta' => 144,
    'minHtlc' => '1000',
    'feeBaseMsat' => '1000',
    'feeRateMilliMsat' => '300',
    'maxHtlcMsat' => '4950000000'
  },
  'advertisingNode' => '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'
}

Lighstorm::Channel.adapt(gossip: gossip)

channel = Lighstorm::Channel.find_by_id('850099509773795329')

diff = channel.apply!(gossip: gossip)

Lighstorm::Channel.adapt(dump: channel.dump)
```

## Satoshis

```ruby
Lighstorm::Satoshis
Lighstorm::Satoshis.new(milisatoshis: 75_621_650)

satoshis.to_h

satoshis.milisatoshis
satoshis.satoshis
satoshis.bitcoins

satoshis.msats
satoshis.sats
satoshis.btc

reference_in_milisatoshis = 75_621_650_000
satoshis.parts_per_million(reference_in_milisatoshis)
```
_________________

<center>
  lighstorm 0.0.6
  |
  <a href="https://github.com/icebaker/lighstorm" rel="noopener noreferrer" target="_blank">GitHub</a>
  |
  <a href="https://rubygems.org/gems/lighstorm" rel="noopener noreferrer" target="_blank">RubyGems</a>
</center>
