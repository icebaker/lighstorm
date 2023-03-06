# frozen_string_literal: true

module Lighstorm
  module Static
    CACHE = {
      lightning_update_channel_policy: false,
      lightning_add_invoice: false,
      router_send_payment_v2: false,
      lightning_fee_report: {
        ttl: 0.01,
        properties: %i[
          base_fee_msat fee_per_mil
        ]
      },
      lightning_decode_pay_req: {
        ttl: 5 * 60
      },
      lightning_describe_graph: {
        ttl: 0
      },
      lightning_lookup_invoice: {
        ttl: 1
      },
      lightning_list_invoices: {
        ttl: 1
      },
      lightning_forwarding_history: {
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
      lightning_get_chan_info: {
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
      lightning_get_info: {
        ttl: 5 * 60,
        properties: %i[identity_pubkey version chains chain network]
      },
      lightning_get_node_info: {
        ttl: 5 * 60,
        properties: %i[alias pub_key color]
      },
      lightning_list_channels: {
        ttl: 1,
        properties: %i[
          local_balance remote_balance unsettled_balance
          local_constraints remote_constraints
          active private
          lifetime uptime
          total_satoshis_sent total_satoshis_received
        ]
      },
      lightning_list_payments: {
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
