# frozen_string_literal: true

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm do
  it 'connects' do
    described_class.add_connection!(
      'alice',
      'lndconnect://127.0.0.1:10001?cert=MIICJzCCAc2gAwIBAgIRAImZs0ieSBjBcMtpD8oQ_okwCgYIKoZIzj0EAwIwMTEfMB0GA1UEChMWbG5kIGF1dG9nZW5lcmF0ZWQgY2VydDEOMAwGA1UEAxMFYWxpY2UwHhcNMjMwMzEyMjM0NDEyWhcNMjQwNTA2MjM0NDEyWjAxMR8wHQYDVQQKExZsbmQgYXV0b2dlbmVyYXRlZCBjZXJ0MQ4wDAYDVQQDEwVhbGljZTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABL8ZHtjXzSy7Qs9SL0wECTsAwyX8xplEox1DQUMnB6mfu5dXxzuTqoyCL1FuwjthqfZNO3hX2O-o5pyHxGkqYA2jgcUwgcIwDgYDVR0PAQH_BAQDAgKkMBMGA1UdJQQMMAoGCCsGAQUFBwMBMA8GA1UdEwEB_wQFMAMBAf8wHQYDVR0OBBYEFFXs5yUhjbRfmlYGGEYPlzquQdslMGsGA1UdEQRkMGKCBWFsaWNlgglsb2NhbGhvc3SCBWFsaWNlgg5wb2xhci1uMS1hbGljZYIEdW5peIIKdW5peHBhY2tldIIHYnVmY29ubocEfwAAAYcQAAAAAAAAAAAAAAAAAAAAAYcErBgABjAKBggqhkjOPQQDAgNIADBFAiBvz_hKoN0JltWgjzBHYHpB4fM2tqPge9j1m1tt0ye8PgIhAJkGw-5chEuH5bVFLBQjo5SUAW_sGX9i0aSqcSJBEERQ&macaroon=AgEDbG5kAvgBAwoQZfbno2BCpVfn-g6USaC3JRIBMBoWCgdhZGRyZXNzEgRyZWFkEgV3cml0ZRoTCgRpbmZvEgRyZWFkEgV3cml0ZRoXCghpbnZvaWNlcxIEcmVhZBIFd3JpdGUaIQoIbWFjYXJvb24SCGdlbmVyYXRlEgRyZWFkEgV3cml0ZRoWCgdtZXNzYWdlEgRyZWFkEgV3cml0ZRoXCghvZmZjaGFpbhIEcmVhZBIFd3JpdGUaFgoHb25jaGFpbhIEcmVhZBIFd3JpdGUaFAoFcGVlcnMSBHJlYWQSBXdyaXRlGhgKBnNpZ25lchIIZ2VuZXJhdGUSBHJlYWQAAAYg61atst43JqOPEZKGrLszr6q8eWVvQfxgr1inv45ukJ4'
    )

    described_class.add_connection!(
      'bob',
      'lndconnect://127.0.0.1:10002?cert=MIICHjCCAcOgAwIBAgIRAKFIzgCaW7Ad8EZ_TNpnQhAwCgYIKoZIzj0EAwIwLzEfMB0GA1UEChMWbG5kIGF1dG9nZW5lcmF0ZWQgY2VydDEMMAoGA1UEAxMDYm9iMB4XDTIzMDMxMjIzNDQxMVoXDTI0MDUwNjIzNDQxMVowLzEfMB0GA1UEChMWbG5kIGF1dG9nZW5lcmF0ZWQgY2VydDEMMAoGA1UEAxMDYm9iMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEBrwjgH47U5oPJ0XF2yn35MLSJw3dt7kRufh4jmlkETiV-5hhDQ-pDrSjkMUaK8Bj4AuZFW5h0NPbHqSX-MjONKOBvzCBvDAOBgNVHQ8BAf8EBAMCAqQwEwYDVR0lBAwwCgYIKwYBBQUHAwEwDwYDVR0TAQH_BAUwAwEB_zAdBgNVHQ4EFgQUfam6_RZHlYm3Xhj07E53WyLcIAcwZQYDVR0RBF4wXIIDYm9igglsb2NhbGhvc3SCA2JvYoIMcG9sYXItbjEtYm9iggR1bml4ggp1bml4cGFja2V0ggdidWZjb25uhwR_AAABhxAAAAAAAAAAAAAAAAAAAAABhwSsGAAFMAoGCCqGSM49BAMCA0kAMEYCIQDMewc33jp0SlMW6xbUJKEPJRUg5tdNg7A8wPrT0fo2_gIhAP1gQFzNV9ffFD7I_y4Pyat49rPqTNBFttLbFUSbUgYw&macaroon=AgEDbG5kAvgBAwoQNPLBvSsr2kM1p0M1OiPRxhIBMBoWCgdhZGRyZXNzEgRyZWFkEgV3cml0ZRoTCgRpbmZvEgRyZWFkEgV3cml0ZRoXCghpbnZvaWNlcxIEcmVhZBIFd3JpdGUaIQoIbWFjYXJvb24SCGdlbmVyYXRlEgRyZWFkEgV3cml0ZRoWCgdtZXNzYWdlEgRyZWFkEgV3cml0ZRoXCghvZmZjaGFpbhIEcmVhZBIFd3JpdGUaFgoHb25jaGFpbhIEcmVhZBIFd3JpdGUaFAoFcGVlcnMSBHJlYWQSBXdyaXRlGhgKBnNpZ25lchIIZ2VuZXJhdGUSBHJlYWQAAAYg79y4thPvtaZ388GF664C1lfRcxPwcZR7HdKzh1ADw48'
    )

    expect(
      VCR.tape.replay('Lighstorm::Node.myself.alias') do
        Lighstorm::Node.myself.alias
      end
    ).to eq('icebaker/old-stone')

    expect(
      VCR.tape.replay('Lighstorm::Node.myself.alias', as: 'alice') do
        Lighstorm::Node.as('alice').myself.alias
      end
    ).to eq('alice')

    expect(
      VCR.tape.replay('Lighstorm::Node.myself.alias', as: 'bob') do
        Lighstorm::Node.as('bob').myself.alias
      end
    ).to eq('bob')

    expect(described_class.connections).to include('alice')
    expect(described_class.connections).to include('bob')

    described_class.remove_connection!('alice')

    expect(described_class.connections).not_to include('alice')
    expect(described_class.connections).to include('bob')
  end
end
