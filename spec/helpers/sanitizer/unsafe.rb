# frozen_string_literal: true

module Sanitizer
  UNSAFE = {
    '_error <= get_chan_info' => true,
    '_error <= lookup_invoice' => true,
    'accept_height <= htlcs' => true,
    'add_index <= list_invoices' => true,
    'add_index <= lookup_invoice' => true,
    'add_index' => true,
    'addr <= addresses' => true,
    'amp <= htlcs' => true,
    'amp_record <= hops' => true,
    'attempt_id <= htlcs' => true,
    'best_header_timestamp <= get_info' => true,
    'best_header_timestamp' => true,
    'block_hash <= get_info' => true,
    'block_hash' => true,
    'block_height <= get_info' => true,
    'block_height' => true,
    'chan_reserve_sat <= local_constraints' => true,
    'chan_reserve_sat <= remote_constraints' => true,
    'chan_status_flags <= list_channels' => true,
    'chan_status_flags' => true,
    'channel_point <= channel_fees' => true,
    'channel_point <= list_channels' => true,
    'channel_point' => true,
    'close_address <= list_channels' => true,
    'close_address' => true,
    'cltv_expiry <= decode_pay_req' => true,
    'cltv_expiry <= list_invoices' => true,
    'cltv_expiry <= lookup_invoice' => true,
    'cltv_expiry' => true,
    'commit_fee <= list_channels' => true,
    'commit_fee' => true,
    'commit_hash <= get_info' => true,
    'commit_hash' => true,
    'commit_weight <= list_channels' => true,
    'commit_weight' => true,
    'commitment_type <= list_channels' => true,
    'commitment_type' => true,
    'csv_delay <= list_channels' => true,
    'csv_delay <= local_constraints' => true,
    'csv_delay <= remote_constraints' => true,
    'csv_delay' => true,
    'custom_records <= htlcs' => true,
    'day_fee_sum <= fee_report' => true,
    'destination <= decode_pay_req' => true,
    'destination' => true,
    'dust_limit_sat <= local_constraints' => true,
    'dust_limit_sat <= remote_constraints' => true,
    'expiration_height <= pending_htlcs' => true,
    'expiry_height <= htlcs' => true,
    'failure <= htlcs' => true,
    'failure_reason <= list_payments' => true,
    'failure_reason' => true,
    'fallback_addr <= decode_pay_req' => true,
    'fallback_addr <= list_invoices' => true,
    'fallback_addr <= lookup_invoice' => true,
    'fallback_addr' => true,
    'forwarding_channel <= pending_htlcs' => true,
    'forwarding_htlc_index <= pending_htlcs' => true,
    'hash_lock <= pending_htlcs' => true,
    'htlc_index <= htlcs' => true,
    'htlc_index <= pending_htlcs' => true,
    'incoming <= pending_htlcs' => true,
    'initiator <= list_channels' => true,
    'initiator' => true,
    'is_amp <= list_invoices' => true,
    'is_amp <= lookup_invoice' => true,
    'is_amp' => true,
    'is_keysend <= list_invoices' => true,
    'is_keysend <= lookup_invoice' => true,
    'is_keysend' => true,
    'is_known <= features' => true,
    'is_required <= features' => true,
    'last_update <= describe_graph' => true,
    'last_update <= get_chan_info' => true,
    'last_update <= node' => true,
    'last_update <= node1_policy' => true,
    'last_update <= node2_policy' => true,
    'last_update' => true,
    'list_payments' => true,
    'local_chan_reserve_sat <= list_channels' => true,
    'local_chan_reserve_sat' => true,
    'max_accepted_htlcs <= local_constraints' => true,
    'max_accepted_htlcs <= remote_constraints' => true,
    'metadata <= hops' => true,
    'month_fee_sum <= fee_report' => true,
    'mpp_record <= hops' => true,
    'name <= features' => true,
    'node1_policy <= describe_graph' => true,
    'node1_policy <= get_chan_info' => true,
    'node1_policy' => true,
    'node2_policy <= describe_graph' => true,
    'node2_policy <= get_chan_info' => true,
    'node2_policy' => true,
    'num_active_channels <= get_info' => true,
    'num_active_channels' => true,
    'num_channels <= get_node_info' => true,
    'num_channels' => true,
    'num_inactive_channels <= get_info' => true,
    'num_inactive_channels' => true,
    'num_peers <= get_info' => true,
    'num_peers' => true,
    'num_pending_channels <= get_info' => true,
    'num_pending_channels' => true,
    'num_updates <= list_channels' => true,
    'num_updates' => true,
    'payment_addr <= decode_pay_req' => true,
    'payment_addr <= list_invoices' => true,
    'payment_addr <= lookup_invoice' => true,
    'payment_addr <= mpp_record' => true,
    'payment_addr' => true,
    'payment_index <= list_payments' => true,
    'payment_index' => true,
    'payment_preimage <= list_payments' => true,
    'payment_preimage' => true,
    'preimage <= htlcs' => true,
    'private <= list_channels' => true,
    'private <= list_invoices' => true,
    'private <= lookup_invoice' => true,
    'push_amount_sat <= list_channels' => true,
    'push_amount_sat' => true,
    'r_preimage <= list_invoices' => true,
    'r_preimage <= lookup_invoice' => true,
    'r_preimage' => true,
    'remote_chan_reserve_sat <= list_channels' => true,
    'remote_chan_reserve_sat' => true,
    'require_htlc_interceptor <= get_info' => true,
    'require_htlc_interceptor' => true,
    'settle_index <= list_invoices' => true,
    'settle_index <= lookup_invoice' => true,
    'settle_index' => true,
    'static_remote_key <= list_channels' => true,
    'static_remote_key' => true,
    'synced_to_chain <= get_info' => true,
    'synced_to_chain' => true,
    'synced_to_graph <= get_info' => true,
    'synced_to_graph' => true,
    'testnet <= get_info' => true,
    'testnet' => true,
    'thaw_height <= list_channels' => true,
    'thaw_height' => true,
    'tlv_payload <= hops' => true,
    'total_time_lock <= route' => true,
    'uris <= get_info' => true,
    'uris' => true,
    'week_fee_sum <= fee_report' => true,
    'zero_conf <= list_channels' => true,
    'zero_conf' => true,
    'zero_conf_confirmed_scid <= list_channels' => true,
    'zero_conf_confirmed_scid' => true
  }.freeze
end