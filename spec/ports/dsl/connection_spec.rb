# frozen_string_literal: true

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Connection do
  it 'connects' do
    described_class.add!(
      'alice',
      'lndconnect://127.0.0.1:10001?cert=MIICLDCCAdKgAwIBAgIQMmDVpggMIsv-zCmmhsX0gTAKBggqhkjOPQQDAjAxMR8wHQYDVQQKExZsbmQgYXV0b2dlbmVyYXRlZCBjZXJ0MQ4wDAYDVQQDEwVhbGljZTAeFw0yMzAzMjUyMjA2MzRaFw0yNDA1MTkyMjA2MzRaMDExHzAdBgNVBAoTFmxuZCBhdXRvZ2VuZXJhdGVkIGNlcnQxDjAMBgNVBAMTBWFsaWNlMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEKuj4GBpfaJD9ZSoZ9U7M0YPMWcElSpcJVr3yTmMbessSQkmYIbKHxcvdM-lXegHr12enWZRYeFJ5exmUx2-u7KOByzCByDAOBgNVHQ8BAf8EBAMCAqQwEwYDVR0lBAwwCgYIKwYBBQUHAwEwDwYDVR0TAQH_BAUwAwEB_zAdBgNVHQ4EFgQUMh4YxF2Vx4belEaRWdXWh0EV3kEwcQYDVR0RBGowaIIFYWxpY2WCCWxvY2FsaG9zdIIFYWxpY2WCDnBvbGFyLW4xLWFsaWNlggR1bml4ggp1bml4cGFja2V0ggdidWZjb25uhwR_AAABhxAAAAAAAAAAAAAAAAAAAAABhwTAqDAChwSsEQABMAoGCCqGSM49BAMCA0gAMEUCIDMcr7-KIGxMvhsUxuBXJko9_k2kAzp7LHROF7AybrROAiEAroRrJ5Fy4C6zKTUEZbQHabaT_z0hZojnBT36d5vUnmA&macaroon=AgEDbG5kAvgBAwoQL_2BTrMSQwJxN-mNIeDkoBIBMBoWCgdhZGRyZXNzEgRyZWFkEgV3cml0ZRoTCgRpbmZvEgRyZWFkEgV3cml0ZRoXCghpbnZvaWNlcxIEcmVhZBIFd3JpdGUaIQoIbWFjYXJvb24SCGdlbmVyYXRlEgRyZWFkEgV3cml0ZRoWCgdtZXNzYWdlEgRyZWFkEgV3cml0ZRoXCghvZmZjaGFpbhIEcmVhZBIFd3JpdGUaFgoHb25jaGFpbhIEcmVhZBIFd3JpdGUaFAoFcGVlcnMSBHJlYWQSBXdyaXRlGhgKBnNpZ25lchIIZ2VuZXJhdGUSBHJlYWQAAAYg6PeTTbBG0SDRBvkUHFaCypq22RChRyMNvnnAjG8mxIk'
    )

    described_class.add!(
      'bob',
      'lndconnect://127.0.0.1:10002?cert=MIICIjCCAcmgAwIBAgIRANOOWibKmQm7XvCRRw-LFE0wCgYIKoZIzj0EAwIwLzEfMB0GA1UEChMWbG5kIGF1dG9nZW5lcmF0ZWQgY2VydDEMMAoGA1UEAxMDYm9iMB4XDTIzMDMyNTIyMjkwN1oXDTI0MDUxOTIyMjkwN1owLzEfMB0GA1UEChMWbG5kIGF1dG9nZW5lcmF0ZWQgY2VydDEMMAoGA1UEAxMDYm9iMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEBZMyLn2WGYp-TDBpHAYogg3gxk23ZBSZIW8W2HDhwX1x5aAjq9aVKFQjsrr3Zplll4TqVMHEo7GphNl5GGfqUaOBxTCBwjAOBgNVHQ8BAf8EBAMCAqQwEwYDVR0lBAwwCgYIKwYBBQUHAwEwDwYDVR0TAQH_BAUwAwEB_zAdBgNVHQ4EFgQU7Yn-Z88-uKb28BkE6Ij25xwWV-cwawYDVR0RBGQwYoIDYm9igglsb2NhbGhvc3SCA2JvYoIMcG9sYXItbjEtYm9iggR1bml4ggp1bml4cGFja2V0ggdidWZjb25uhwR_AAABhxAAAAAAAAAAAAAAAAAAAAABhwTAqEAChwSsEQABMAoGCCqGSM49BAMCA0cAMEQCIBsBzUVbBlWVBkORVSUaMiorbuJ7NNvV-UC1o3H7vWQEAiACcJCsFi-PX-Zdu--m-wh1gq6Cdp_6EVfzh1-6aCYQRg&macaroon=AgEDbG5kAvgBAwoQZjAOcyRGBSs8v9wLJ3Xv6BIBMBoWCgdhZGRyZXNzEgRyZWFkEgV3cml0ZRoTCgRpbmZvEgRyZWFkEgV3cml0ZRoXCghpbnZvaWNlcxIEcmVhZBIFd3JpdGUaIQoIbWFjYXJvb24SCGdlbmVyYXRlEgRyZWFkEgV3cml0ZRoWCgdtZXNzYWdlEgRyZWFkEgV3cml0ZRoXCghvZmZjaGFpbhIEcmVhZBIFd3JpdGUaFgoHb25jaGFpbhIEcmVhZBIFd3JpdGUaFAoFcGVlcnMSBHJlYWQSBXdyaXRlGhgKBnNpZ25lchIIZ2VuZXJhdGUSBHJlYWQAAAYgDZdbNEdhKl3abn3akDSo1dQn86sVOTxta3yIn6Q0ICk'
    )

    expect(
      VCR.tape.replay('Lighstorm::Connection.default.keys') do
        described_class.default.keys.sort
      end
    ).to include(
      :address, :certificate, :macaroon
    )

    expect(
      VCR.tape.replay('Lighstorm::Connection.default.address') do
        described_class.default[:address]
      end
    ).to eq(
      '127.0.0.1:10002'
    )

    expect(described_class.for('alice').keys.sort).to include(
      :connect, :address, :certificate, :macaroon
    )

    expect(described_class.for('alice')[:address]).to eq(
      '127.0.0.1:10001'
    )

    expect(
      VCR.tape.replay('Lighstorm::Lightning::Node.myself.alias') do
        Lighstorm::Lightning::Node.myself.alias
      end
    ).to eq('bob')

    expect(
      VCR.tape.replay('Lighstorm::Lightning::Node.myself.alias', as: 'alice') do
        Lighstorm::Lightning::Node.as('alice').myself.alias
      end
    ).to eq('alice')

    expect(
      VCR.tape.replay('Lighstorm::Lightning::Node.myself.alias', as: 'bob') do
        Lighstorm::Lightning::Node.as('bob').myself.alias
      end
    ).to eq('bob')

    expect(described_class.all).to include('alice')
    expect(described_class.all).to include('bob')

    described_class.remove!('alice')

    expect(described_class.all).not_to include('alice')
    expect(described_class.all).to include('bob')
  end
end
