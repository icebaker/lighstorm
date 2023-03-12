> ⚠️ Warning: Early-stage project, breaking changes are expected.

# About

> Lighstorm: API for interacting with a [Lightning Node](https://lightning.network).

_Lighstorm_ is an opinionated abstraction layer on top of the [lnd-client](https://github.com/icebaker/lnd-client).

It brings an [_object-oriented_](https://en.wikipedia.org/wiki/Object-oriented_programming) approach for interacting with a [Lightning Node](https://github.com/lightningnetwork/lnd), influenced by the [Active Record Pattern](https://www.martinfowler.com/eaaCatalog/activeRecord.html) and [Active Record Models](https://guides.rubyonrails.org/active_record_basics.html) conventions.

However, despite the fluidity of _Object Orientation_ being desired in its public interface, internally, most of its code is structured following the [_Hexagonal Architecture_](https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)) and [_Functional Programming_](https://en.wikipedia.org/wiki/Functional_programming) principles.

It aims to be intuitive to use while being highly **reliable**, as it deals with people's money, and easily testable since its [tests](?id=testing) are the foundation for its reliability.

Although it tries to stay close to [Lightning's terminologies](https://docs.lightning.engineering/the-lightning-network/overview), it brings its own vocabulary and [data modeling](?id=data-modeling), optimizing for [programmer happiness](https://rubyonrails.org/doctrine#optimize-for-programmer-happiness).

# Getting Started

![Lighstorm text written stylized with an illustration of a Graph connecting two Nodes.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/lighstorm.png)

```ruby
Lighstorm::Channel.mine.first.myself.node.alias
```

## Installing

Add to your `Gemfile`:

```ruby
gem 'lighstorm', '~> 0.0.10'
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

puts Lighstorm.version # => 0.0.10

Lighstorm::Invoice.create(
  description: 'Coffee', amount: { millisatoshis: 1000 }, payable: 'once'
)

Lighstorm::Invoice.decode('lnbc20m1pv...qqdhhwkj').pay

Lighstorm::Invoice.decode('lnbc20m1pv...qqdhhwkj').pay(
  fee: { maximum: { millisatoshis: 1000 } }
)

Lighstorm::Node.find_by_public_key(
  '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'
).pay(amount: { millisatoshis: 1000 })

Lighstorm::Node.find_by_public_key(
  '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'
).send_message('Hello from Lighstorm!', amount: { millisatoshis: 1000 })

Lighstorm::Node.myself.alias # => icebaker/old-stone
Lighstorm::Node.myself.public_key # => 02d3...e997

Lighstorm::Node.myself.to_h #> { ... }

Lighstorm::Node.myself.channels.count # => 5

Lighstorm::Channel.mine.first.partner.node.alias

forward = Lighstorm::Forward.all(limit: 10).first

forward.in.amount.millisatoshis # => 75621650
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

Lighstorm::Satoshis.new(
  millisatoshis: 75621650
).satoshis # => 75621.65
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

### Channel

```ruby
channel = Lighstorm::Channel.mine.first

channel.id

channel.accounting.capacity.millisatoshis

channel.partner.accounting.balance.millisatoshis
channel.partner.node.alias
channel.partner.policy.fee.rate.parts_per_million

channel.myself.accounting.balance.millisatoshis
channel.myself.node.alias
channel.myself.policy.fee.rate.parts_per_million
```

[![This is an image representing Channel as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-channel.png)](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-channel.png)
<center style="margin-top: -1.4em;">
  <a href="https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-channel.png" rel="noopener noreferrer" target="_blank">
    click to zoom
  </a>
</center>

### Forward

```ruby
forward = Lighstorm::Forward.last

forward.at

forward.fee.millisatoshis
forward.fee.parts_per_million(
  forward.in.amount.millisatoshis
)

forward.in.amount.millisatoshis
forward.out.amount.millisatoshis

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

### Payment

```ruby
payment = Lighstorm::Payment.last

payment.at
payment.state

# https://github.com/lightning/bolts/blob/master/11-payment-encoding.md
payment.invoice.code # "lnbc20m1pv...qqdhhwkj"

payment.invoice.amount.millisatoshis

payment.from.hop
payment.from.amount.millisatoshis
payment.from.fee.millisatoshis
payment.from.channel.id
payment.from.channel.target.alias
payment.from.channel.exit.alias

payment.to.hop
payment.to.amount.millisatoshis
payment.to.fee.millisatoshis
payment.to.channel.id
payment.to.channel.target.alias

payment.hops[0].hop
payment.hops[0].amount.millisatoshis
payment.hops[0].fee.millisatoshis
payment.hops[0].channel.id
payment.hops[0].channel.target.alias
```

[![This is an image representing Payment as a graph.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-payment.png)](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-payment.png)
<center style="margin-top: -1.4em;">
  <a href="https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/graph-payment.png" rel="noopener noreferrer" target="_blank">
    click to zoom
  </a>
</center>

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

### Pay

Read more about [_Spontaneous Payments_](https://docs.lightning.engineering/lightning-network-tools/lnd/send-messages-with-keysend#send-a-spontaneous-payment).

```ruby
destination = Lighstorm::Node.find_by_public_key(
  '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'
)

destination.alias # => 'icebaker/old-stone'

destination.pay(amount: { millisatoshis: 1000 })

destination.pay(
  amount: { millisatoshis: 1500 },
  fee: { maximum: { millisatoshis: 1000 } },
  message: 'Hello from Lighstorm!',
  through: 'amp',
  times_out_in: { seconds: 5 }
)

destination.pay(
  amount: { millisatoshis: 1200 },
  fee: { maximum: { millisatoshis: 1000 } },
  message: 'Hello from Lighstorm!',
  through: 'keysend',
  times_out_in: { seconds: 5 }
)

action = destination.pay(amount: { millisatoshis: 1000 })
action.result.fee.millisatoshis
```

### Send Messages

**Warning:** Sending messages through Lightning Network requires you to spend satoshis and potentially pay fees.

```ruby
destination = Lighstorm::Node.find_by_public_key(
  '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'
)

destination.alias # => 'icebaker/old-stone'

destination.send_message(
  'Hello from Lighstorm!',
  amount: { millisatoshis: 1000 }
)

destination.send_message(
  'Hello from Lighstorm!',
  amount: { millisatoshis: 1000 },
  fee: { maximum: { millisatoshis: 1000 } },
  through: 'amp',
  times_out_in: { seconds: 5 }
)

destination.send_message(
  'Hello from Lighstorm!',
  amount: { millisatoshis: 1000 },
  fee: { maximum: { millisatoshis: 1000 } },
  through: 'keysend',
  times_out_in: { seconds: 5 }
)

action = destination.send_message(
  'Hello from Lighstorm!',
  amount: { millisatoshis: 1000 }
)
action.result.fee.millisatoshis
```

Read more about sending messages:
- [_Send a message to other nodes_](https://docs.lightning.engineering/lightning-network-tools/lnd/send-messages-with-keysend#send-a-message-to-other-nodes)
- [_Does Private messaging over Bitcoin’s Lightning Network have potential?_](https://cryptopurview.com/private-messaging-over-bitcoins-lightning-network/)
- [_How Bitcoin's Lightning Can Be Used for Private Messaging_](https://www.coindesk.com/markets/2019/11/09/how-bitcoins-lightning-can-be-used-for-private-messaging/)

### Error Handling
Same error handling used for [Invoices Payment Errors](?id=error-handling-1)

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

channel.accounting.capacity.millisatoshis
channel.accounting.sent.millisatoshis
channel.accounting.received.millisatoshis
channel.accounting.unsettled.millisatoshis

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

channel.partner.accounting.balance.millisatoshis

channel.partner.policy.fee.base.millisatoshis
channel.partner.policy.fee.rate.parts_per_million

channel.partner.policy.htlc.minimum.millisatoshis
channel.partner.policy.htlc.maximum.millisatoshis
channel.partner.policy.htlc.blocks.delta.minimum

channel.myself
channel.myself.state
channel.myself.active?

channel.myself.node.public_key
channel.myself.node.alias
channel.myself.node.color

channel.myself.accounting.balance.millisatoshis

channel.myself.policy.fee.base.millisatoshis
channel.myself.policy.fee.rate.parts_per_million

channel.myself.policy.htlc.minimum.millisatoshis
channel.myself.policy.htlc.maximum.millisatoshis
channel.myself.policy.htlc.blocks.delta.minimum
```

### Fee Update

```ruby
channel = Lighstorm::Channel.mine.first

# 'preview' let you check the expected operation
# before actually performing it for debug purposes
channel.myself.policy.fee.update(
  { rate: { parts_per_million: 25 } }, preview: true
)

channel.myself.policy.fee.update(
  { base: { millisatoshis: 1 } }
)

channel.myself.policy.fee.update(
  { rate: { parts_per_million: 25 } }
)

channel.myself.policy.fee.update(
  { base: { millisatoshis: 1 }, rate: { parts_per_million: 25 } }
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

Lighstorm::Invoice.decode('lnbc20n1pj...0eqps7h0k9')

Lighstorm::Invoice.find_by_secret_hash(
  '1d438b8100518c9fba0a607e3317d6b36f74ceef3a6591836eb2f679c6853501'
)

invoice = Lighstorm::Invoice.find_by_code('lnbc20n1pj...0eqps7h0k9')

invoice.secret.valid_proof?(
  'c504f73f83e3772b802844b54021e44e071c03011eeda476b198f7a093bcb09e'
) # => true

# _key is helpful for reactive javascript frameworks.
# Please don't consider it as a unique identifier
# for the item. Instead, use it as a volatile key for
# the item's current state that may change at any moment.
invoice._key

invoice.created_at
invoice.expires_at
invoice.settled_at

invoice.state

# https://github.com/lightning/bolts/blob/master/11-payment-encoding.md
invoice.code # "lnbc20m1pv...qqdhhwkj"

invoice.amount.millisatoshis

invoice.payable # 'once' or 'indefinitely'

invoice.description.memo
invoice.description.hash

# https://docs.lightning.engineering/the-lightning-network/multihop-payments
invoice.secret.preimage
invoice.secret.hash
```

### Create

[Understanding Lightning Invoices](https://docs.lightning.engineering/the-lightning-network/payment-lifecycle/understanding-lightning-invoices)

```ruby
# 'preview' let you check the expected operation
# before actually performing it for debug purposes
preview = Lighstorm::Invoice.create(
  description: 'Coffee', amount: { millisatoshis: 1000 },
  payable: 'once', preview: true
)

action = Lighstorm::Invoice.create(
  description: 'Coffee', amount: { millisatoshis: 1000 },
  payable: 'once', expires_in: { minutes: 5 }
)

action = Lighstorm::Invoice.create(
  description: 'Beer', payable: 'once'
)

action = Lighstorm::Invoice.create(
  description: 'Donations', payable: 'indefinitely',
  expires_in: { hours: 24 }
)

action = Lighstorm::Invoice.create(
  description: 'Concert Ticket', amount: { millisatoshis: 500000000 },
  payable: 'indefinitely', expires_in: { days: 5 }
)

action.to_h

action.response
invoice = action.result
```

### Proof of Payment

[Making Payments](https://docs.lightning.engineering/the-lightning-network/multihop-payments)


```ruby
invoice = Lighstorm::Invoice.find_by_code('lnbc20n1pj...0eqps7h0k9')

invoice.secret.valid_proof?(
  'c504f73f83e3772b802844b54021e44e071c03011eeda476b198f7a093bcb09e'
) # => true
```

### Pay

[Understanding Lightning Invoices](https://docs.lightning.engineering/the-lightning-network/payment-lifecycle/understanding-lightning-invoices)

```ruby
invoice = Lighstorm::Invoice.decode('lnbc20m1pv...qqdhhwkj')

# 'preview' let you check the expected operation
# before actually performing it for debug purposes
invoice.pay(preview: true)

action = invoice.pay

action.to_h

action.response
payment = action.result

payment.at
payment.state

payment.secret.proof

payment.amount.millisatoshis
payment.fee.millisatoshis
payment.fee.parts_per_million(
  payment.amount.millisatoshis
)

payment.purpose
payment.hops.size
```

```ruby
invoice.pay(
  amount: { millisatoshis: 1500 },
  fee: { maximum: { millisatoshis: 1000 } },
  message: 'here we go',
  times_out_in: { seconds: 5 }
)
```

#### Error Handling
Check [Error Handling](?id=error-handling-2)

```ruby
begin
  invoice.pay
rescue AlreadyPaidError => error
  error.message # 'The invoice is already paid.'
  error.grpc.class # GRPC::AlreadyExists
  error.grpc.message # '6:invoice is already paid. debug_error_string:{UNKNOWN...'
end
```

```ruby
begin
  invoice.pay(amount: { millisatoshis: 1000 })
rescue AmountForNonZeroError => error
  error.message # 'Millisatoshis must not be specified...'
  error.grpc.class # GRPC::Unknown
  error.grpc.message # '2:amount must not be specified when paying...'
end
```

```ruby
begin
  invoice.pay
rescue MissingMillisatoshisError => error
  error.message # 'Millisatoshis must be specified...'
  error.grpc.class # GRPC::Unknown
  error.grpc.message # '2:amount must be specified when paying a zero...'
end
```

```ruby
begin
  invoice.pay
rescue NoRouteFoundError => error
  error.message # 'FAILURE_REASON_NO_ROUTE'
  e.response
  e.response.last[:failure_reason] # => :FAILURE_REASON_NO_ROUTE
end
```


```ruby
begin
  invoice.pay
rescue PaymentError => error
  error.class
  error.message

  error.grpc
  error.response
  error.result
end
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
# 'self-payment', 'peer-to-peer',
# 'rebalance', 'payment'

Lighstorm::Payment.find_by_invoice_code('lnbc20n1pj...0eqps7h0k9')

Lighstorm::Payment.find_by_secret_hash(
  '1d438b8100518c9fba0a607e3317d6b36f74ceef3a6591836eb2f679c6853501'
)

# _key is helpful for reactive javascript frameworks.
# Please don't consider it as a unique identifier
# for the item. Instead, use it as a volatile key for
# the item's current state that may change at any moment.
payment._key

payment.to_h

payment.at

payment.amount.millisatoshis

payment.fee.millisatoshis
payment.fee.parts_per_million(
  payment.amount.millisatoshis
)

payment.state
payment.message

payment.how # 'spontaneously', 'with-invoice'
payment.through # 'keysend', 'amp', 'non-amp'
payment.purpose
# 'self-payment', 'peer-to-peer',
# 'rebalance', 'payment'

# https://docs.lightning.engineering/the-lightning-network/multihop-payments
payment.secret.preimage
payment.secret.hash
payment.secret.proof

payment.invoice.created_at
payment.invoice.expires_at
payment.invoice.settled_at

payment.invoice.state

# https://github.com/lightning/bolts/blob/master/11-payment-encoding.md
payment.invoice.code # "lnbc20m1pv...qqdhhwkj"
payment.invoice.amount.millisatoshis

payment.invoice.payable # 'once', 'indefinitely'

payment.invoice.description.memo
payment.invoice.description.hash

# https://docs.lightning.engineering/the-lightning-network/multihop-payments
payment.invoice.secret.preimage
payment.invoice.secret.hash

payment.from.hop
payment.from.amount.millisatoshis
payment.from.fee.millisatoshis
payment.from.fee.parts_per_million(
  payment.from.amount.millisatoshis
)

payment.from.channel.id

payment.from.channel.target.public_key
payment.from.channel.target.alias
payment.from.channel.target.color

payment.from.channel.exit.public_key
payment.from.channel.exit.alias
payment.from.channel.exit.color

payment.to.hop
payment.to.amount.millisatoshis
payment.to.fee.millisatoshis
payment.to.fee.parts_per_million(
  payment.to.amount.millisatoshis
)

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
payment.hops[0].amount.millisatoshis
payment.hops[0].fee.millisatoshis
payment.hops[0].fee.parts_per_million(
  payment.hops[0].amount.millisatoshis
)

payment.hops[0].channel.id

payment.hops[0].channel.target.public_key
payment.hops[0].channel.target.alias
payment.hops[0].channel.target.color

payment.hops[0].channel.entry.public_key
payment.hops[0].channel.entry.alias
payment.hops[0].channel.entry.color
```

### Proof of Payment

[Making Payments](https://docs.lightning.engineering/the-lightning-network/multihop-payments)

```ruby
payment = Lighstorm::Invoice.decode('lnbc20m1pv...qqdhhwkj').pay.result

payment.secret.proof
# => 'c504f73f83e3772b802844b54021e44e071c03011eeda476b198f7a093bcb09e'
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

forward.fee.millisatoshis
forward.fee.parts_per_million(
  forward.in.amount.millisatoshis
)

forward.in.amount.millisatoshis

forward.in.channel.id
forward.in.channel.partner.node.alias
forward.in.channel.partner.node.public_key
forward.in.channel.partner.node.color

forward.out.amount.millisatoshis

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
group.analysis.sums.amount.millisatoshis
group.analysis.sums.fee.millisatoshis
group.analysis.averages.amount.millisatoshis
group.analysis.averages.fee.millisatoshis
group.analysis.averages.fee.parts_per_million(
  group.analysis.averages.amount.millisatoshis
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
Lighstorm::Satoshis.new(bitcoins: 0.005)
Lighstorm::Satoshis.new(millisatoshis: 75621650)

satoshis.to_h

satoshis.millisatoshis
satoshis.satoshis
satoshis.bitcoins

satoshis.msats
satoshis.sats
satoshis.btc

reference_in_millisatoshis = 75621650000
satoshis.parts_per_million(reference_in_millisatoshis)
```

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

ArgumentError
IncoherentGossipError
MissingCredentialsError
MissingGossipHandlerError
MissingPartsPerMillionError
NegativeNotAllowedError
NotYourChannelError
NotYourNodeError
OperationNotAllowedError
TooManyArgumentsError
UnexpectedNumberOfHTLCsError
UnknownChannelError
UpdateChannelPolicyError

PaymentError

AlreadyPaidError
AmountForNonZeroError
MissingMillisatoshisError
NoRouteFoundError
```

# Development

Copy the `.env.example` file to `.env` and provide the required data.

```ruby
# Gemfile
gem 'lighstorm', path: '/home/user/lighstorm'

# demo.rb
require 'lighstorm'

puts Lighstorm.version # => 0.0.10
```

```sh
bundle
rubocop -A
```

## Testing

Copy the `.env.example` file to `.env` and provide the required data.

```
bundle

bundle exec rspec
```
### Approach

Writing tests for software that indirectly performs [blockchain](https://en.wikipedia.org/wiki/Blockchain) operations, relies on an external [gRPC](https://grpc.io) API, and is highly influenced by volatile and uncertain [states](https://en.wikipedia.org/wiki/State_(computer_science)) can be [challenging](https://www.youtube.com/watch?v=lKXe3HUG2l4).

While aiming for the _look and feel_ of _[Object Orientation](https://en.wikipedia.org/wiki/Object-oriented_programming)_, I don't want a mesh of objects with volatile states that can change at any time. I'm not saying it wouldn't be possible to make it reliable and easily testable this way, but I choose to follow a [_Functional Programming_](https://en.wikipedia.org/wiki/Functional_programming) approach internally, as my knowledge and experience can provide greater reliability for the software this way.

The core idea is to separate **data** from **behavior** as much as possible. So, a _Model_ internally is just a dummy wrapper that _models_ the data to provide a fluid experience. Alongside that, I make things as [small as possible](https://www.youtube.com/watch?v=8bZh5LMaSmE) and extract desired results from composing them.

Let's get practical.

#### Requesting

To _request_ all Nodes you:
```ruby
Lighstorm::Node.all
```

Internally, what's happening:
```ruby
nodes = Lighstorm::Node.all

         data = Controllers::Node::All.fetch # side effect
      adapted = Controllers::Node::All.adapt(data) # pure
  transformed = Controllers::Node::All.transform(adapted) # pure
       models = Controllers::Node::All.model(transformed) # pure
        nodes = models # pure

nodes.first.public_key
```

So, `fetch` -> `adapt` -> `transform` -> `model`:

![A diagram illustrating the Request Process described above.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/request.png)

The advantage of this approach is that only `fetch` may generate [side effects](https://en.wikipedia.org/wiki/Side_effect_(computer_science)). All other methods ( `adapt`, `transform`,  `model`) are [pure functions](https://en.wikipedia.org/wiki/Pure_function). This means that most of the code is easily testable and reliable, and `fetch` is the only thing we need [mock](https://en.wikipedia.org/wiki/Mock_object) in tests and worry about possible side effects.

The downside is that we can't [lazy-load](https://en.wikipedia.org/wiki/Lazy_loading) data, as we must know what data we will need beforehand.

#### Performing Actions

To perform an _action_, like creating an Invoice, you:
```ruby
Lighstorm::Invoice.create(
  description: 'Coffee', amount: { millisatoshis: 1000 }
)
```

Internally, what's happening:
```ruby
action = Lighstorm::Invoice.create(
  description: 'Coffee', amount: { millisatoshis: 1000 }
)

   request = Controllers::Invoice::Create.prepare(params) # pure
  response = Controllers::Invoice::Create.dispatch(request) # side effect
   adapted = Controllers::Invoice::Create.adapt(response) # pure
      data = Controllers::Invoice::Create.fetch(adapted) # side effect
     model = Controllers::Invoice::Create.model(data) # pure
    action = { response: response, result: model } # pure

invoice = action.result
```

So, `prepare` -> `dispatch` -> `adapt` -> `fetch` -> `model`:

![A diagram illustrating the Action Process described above.](https://raw.githubusercontent.com/icebaker/assets/main/lighstorm/action.png)

The advantage of this approach is that only `dispatch` and `fetch` may generate [side effects](https://en.wikipedia.org/wiki/Side_effect_(computer_science)). All other methods ( `prepare`, `adapt`,  `model`) are [pure functions](https://en.wikipedia.org/wiki/Pure_function). This means that most of the code is easily testable and reliable. `dispatch` and `fetch` are the only things we need [mock](https://en.wikipedia.org/wiki/Mock_object) in tests and worry about possible side effects.

### VCR

After understanding the [approach](?id=approach), we need to make [mocking](https://en.wikipedia.org/wiki/Mock_object) as straightforward as possible for a painless test writing experience, which leads to lots of tests being written, improving the reliability of the code.

_Mock_ is not precisely the approach we are going to use. Instead, we're going to make side effects easily reproducible. The internal [VCR](https://github.com/icebaker/lighstorm/blob/main/spec/helpers/vcr.rb) helper - _whose name is influenced by the [vcr](https://github.com/vcr/vcr) project but has an entirely different implementation_ - provides two kinds of reproducible recordings:

**Tape:**

It is a kind of recording that is easily generated, leading you to frequently delete them and recreate new ones without concerns. You will likely use it for [_requests_](?id=requesting), like fetching Node data. It remembers a real-life [Tape](https://en.wikipedia.org/wiki/Cassette_tape) that is easy to record with a [VCR](https://en.wikipedia.org/wiki/Videocassette_recorder).

**Reel:**

It is a kind of recording that is not so easily generated, leading you to avoid generating them as much as possible. You will likely use it for [_actions_](?id=performing-actions) like paying an Invoice. It remembers a real-life [Film Reel](https://en.wikipedia.org/wiki/Film_stock) that requires a lot of work to [process](https://en.wikipedia.org/wiki/Photographic_processing).

#### Replaying

To create a replayable _Tape_:

```ruby
public_key = '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'

data = VCR.tape.replay('lightning.get_node_info', pub_key: public_key) do
  Lighstorm::Ports::GRPC.lightning.get_node_info(pub_key: public_key).to_h
end
```

It will generate a `.bin` file inside `spec/data/tapes/` containing the data [_marshaled_](https://ruby-doc.org/core-3.0.0/Marshal.html).

If you want to force the overwrite of a Tape, replace `replay` with `replay!` Remember to undo it afterward, replacing `replay!` with `replay`.

To create a replayable _Reel_, just do all the same, but replace `VCR.tape` with `VCR.reel`:

```ruby
response = VCR.reel.replay(
  'lightning.add_invoice',
  memo: 'Coffee', value_msat: 1000
) do
  Lighstorm::Ports::GRPC.lightning.add_invoice(
    memo: 'Coffee', value_msat: 1000
  ).to_h
end
```

By understanding its basic operation, you can become creative using [Proc](https://ruby-doc.org/core-3.0.0/Proc.html). Search the code for [`VCR.tape.replay`](https://github.com/icebaker/lighstorm/search?q=VCR.tape.replay&type=code) or  [`VCR.reel.replay`](https://github.com/icebaker/lighstorm/search?q=VCR.reel.replay&type=code) to understand its practical use.

#### Security

Ideally, you will write and run your tests over some Bitcoin [Testnet](https://en.wikipedia.org/wiki/Testnet). There are tools for helping you build a Test Environment like [_Polar_](https://lightningpolar.com).

Regardless, all _Tapes_ and _Reels_ undergo a [sanitization](https://github.com/icebaker/lighstorm/blob/main/spec/helpers/sanitizer_spec.rb) process before being recorded to remove potentially dangerous (like `payment_preimage`) or privacy-exposing (like `payment_addr`) data. All data potentially [unsafe](https://github.com/icebaker/lighstorm/blob/main/spec/helpers/sanitizer/unsafe.rb) is replaced by randomly generated data of equivalent type and size. If unknown data emerges, it needs to be classified as [safe](https://github.com/icebaker/lighstorm/blob/main/spec/helpers/sanitizer/safe.rb) or [unsafe](https://github.com/icebaker/lighstorm/blob/main/spec/helpers/sanitizer/unsafe.rb). Otherwise, it will be impossible to be recorded, generating an [error](https://github.com/icebaker/lighstorm/blob/main/spec/helpers/sanitizer.rb#L102).

### Contracts

Sometimes you are interested in testing the _shape_ of something instead of its _content_. Symptoms of this appear when you change something in your code and have to mechanically fix dozens of tests because of a minor thing that doesn't make a real difference to what you are testing. This may lead you to avoid doing some important changes because it will be too boring to fix the tests.

It usually plays like this:

```ruby
expect(something.to_h).to eq(
  { created_at: '2023-02-26 15:01:45 UTC',
    title: 'Coffee',
    price: 1000 }
)
```

And then you change something, and it breaks multiple tests because `'2023-02-26 15:01:45 UTC'` becomes `'2023-02-26 15:03:29 UTC'` and `1000` becomes `950`.

You already have other tests ensuring that the `created_at` and `price` are correct, and in this specific test, you just want to ensure that `to_h` generates the expected output _shape_.

So after patiently spending hours and hours fixing these little unimportant changes, you give up on creating new tests like these and eventually even deleting the old ones because it's too much work to maintain them, reducing your test coverage.

Well, this is happening because you are testing the **wrong** thing. You don't care about each minimal bit of the content in this test, only its _approximate shape_. This is similar to the idea of a [_Contract Test_](https://martinfowler.com/bliki/ContractTest.html).

To ensure that writing tests will be as painless as possible, we have a [helper for testing _contracts_](https://github.com/icebaker/lighstorm/blob/main/spec/helpers/contract_spec.rb):

```ruby
expect(Contract.for(something.to_h)).to eq(
  { created_at: 'String:21..30',
    price: 'Integer:0..10',
    title: 'String:0..10' }
)
```

That's it. No matter the date, your test will pass as long as `created_at` is a `String` between 21 and 30 characters.

Also, sometimes you end up with a test that contains a `Hash` with 100+ lines. While it's good to have the contract visible when it's short, if it's too long, we can just use a [hashed version](https://en.wikipedia.org/wiki/Hash_function) of the contract to ensure that it's not being broken:

```ruby
Contract.expect(
  something.to_h, '77b0c3a51abe6'
) do |actual, expected|
  expect(actual.hash).to eq(expected.hash)
  expect(actual.contract).to eq(expected.contract)
end
```

It will generate a `.bin` file inside `spec/data/contracts/` containing the contract [_marshaled_](https://ruby-doc.org/core-3.0.0/Marshal.html), and if it changes, the `77b0c3a51abe6` hash will change, and your test will fail.

Inside the block, you can inspect the actual data with `actual.data`. For generating a contract for the first time, use `expect!` with a `nil` hash:

```ruby
Contract.expect!(
  something.to_h, nil
) do |actual, expected|
  expect(actual.hash).to eq(expected.hash)
  expect(actual.contract).to eq(expected.contract)
end
```

Your contract will be generated, and you can get its hash from the `rspec` output:

```ruby
expected: nil
     got: "77b0c3a51abe67133e981bc362430b2600d23200e9b3b335c890a975bda44575"
```

Remember to undo it afterward, replacing `expect!` with `expect`.

### Extra Tips for Testing

To auto-fix contracts:

```sh
rspec --format json | bundle exec rake contracts:fix
```

To delete unused test data files, update the `.env` file:
```sh
LIGHSTORM_DELETE_UNUSED_TEST_DATA=true
```

Deletion will only occur if you run all tests and no failures are found:
```ruby
bundle exec rspec
```

## Generating Documentation

```sh
npm i docsify-cli -g

docsify serve ./docs
```

## Publish to RubyGems

```sh
gem build lighstorm.gemspec

gem signin

gem push lighstorm-0.0.10.gem
```

_________________

<center>
  lighstorm 0.0.10
  |
  <a href="https://github.com/icebaker/lighstorm" rel="noopener noreferrer" target="_blank">GitHub</a>
  |
  <a href="https://rubygems.org/gems/lighstorm" rel="noopener noreferrer" target="_blank">RubyGems</a>
</center>
