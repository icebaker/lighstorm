# frozen_string_literal: true

module Lighstorm
  module Static
    CACHE = {
      update_channel_policy: false,
      add_invoice: false,
      fee_report: {
        ttl: 0.01,
        properties: %i[
          base_fee_msat fee_per_mil
        ]
      },
      decode_pay_req: {
        ttl: 5 * 60
      },
      describe_graph: {
        ttl: 0
      },
      lookup_invoice: {
        ttl: 1
      },
      list_invoices: {
        ttl: 1
      },
      forwarding_history: {
        ttl: 1,
        properties: %i[
          amt_in_msat
          amt_out_msat
          chan_id_in
          chan_id_out
          fee_msat
          timestamp_ns
        ]
      },
      get_chan_info: {
        ttl: 5 * 60,
        properties: %i[
          channel_id
          chan_point
          node1_pub
          node1_policy
          node2_pub
          node2_policy
          capacity
        ]
      },
      get_info: {
        ttl: 5 * 60,
        properties: %i[identity_pubkey version chains chain network]
      },
      get_node_info: {
        ttl: 5 * 60,
        properties: %i[alias pub_key color]
      },
      list_channels: {
        ttl: 1,
        properties: %i[
          local_balance remote_balance unsettled_balance
          local_constraints remote_constraints
          active private
          lifetime uptime
          total_satoshis_sent total_satoshis_received
        ]
      },
      list_payments: {
        ttl: 1,
        properties: %i[
          creation_date payment_hash status
          value_msat fee_msat
          htlcs route hops
          chan_id pub_key
          amt_to_forward_msat fee_msat
        ]
      }
    }.freeze
  end
end
