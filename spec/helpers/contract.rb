# frozen_string_literal: true

require 'digest'

require 'fileutils'

module Contract
  GENERATE = false

  def self.expect!(actual_data, expected_hash, &block)
    expect(actual_data, expected_hash, generate: true, &block)
  end

  def self.expect(actual_data, expected_hash, generate: GENERATE, &block)
    actual_contract = generate(actual_data)
    actual_hash = hash(actual_contract, save_to_disk: generate)

    expected_contract = load_contract(expected_hash)

    actual = Struct.new(:actual) do
      def data
        actual[:data]
      end

      def contract
        actual[:contract]
      end

      def hash
        actual[:hash]
      end
    end.new({ contract: actual_contract, hash: actual_hash, data: actual_data })

    expected = Struct.new(:expected) do
      def contract
        expected[:contract]
      end

      def hash
        expected[:hash]
      end
    end.new({ contract: expected_contract, hash: expected_hash })

    block.call(actual, expected)
  end

  def self.load_contract(contract_hash)
    path = path_for(contract_hash)

    return nil if path.nil?

    return nil unless File.exist?(path)

    Marshal.load(File.read(path))
  end

  def self.for(data)
    generate(data)
  end

  def self.hash(contract, save_to_disk: false)
    contract_hash = Digest::SHA256.hexdigest(Marshal.dump(contract))

    if save_to_disk
      path = path_for(contract_hash)

      unless File.exist?(path)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, Marshal.dump(contract))
      end
    end

    contract_hash
  end

  def self.path_for(contract_hash)
    return nil unless !contract_hash.nil? && contract_hash.size == 64

    chunk = 16
    parts = contract_hash.scan(/.{#{chunk}}/)

    raise "invalid chunck size (#{chunk}) for contract" if parts.join != contract_hash

    path = "spec/data/contracts/#{parts.join('/')}.bin"
  end

  def self.generate(data)
    contract = apply(Marshal.load(Marshal.dump(data)))
  end

  def self.apply(node)
    case node
    when Hash
      result = {}
      node.keys.sort.each { |key| result[key] = apply(node[key]) }
    when Array
      result = []
      node.each { |value| result << apply(value) }
    else
      result = contract_type(node)
    end

    result
  end

  def self.contract_size(size)
    if size <= 10
      '0..10'
    elsif size <= 20
      '11..20'
    elsif size <= 30
      '21..30'
    elsif size <= 40
      '31..40'
    elsif size <= 50
      '41..50'
    else
      '50+'
    end
  end

  def self.contract_type(node)
    size = nil

    case node
    when Integer, Float, Symbol
      size = contract_size(node.to_s.size)
    when String
      size = contract_size(node.size)
    when NilClass, Time
    when FalseClass, TrueClass
      return 'Boolean'
    else
      raise "missing contract type for #{node.class}"
    end

    type = node.class.to_s.gsub(/Class$/, '')

    return type if size.nil?

    "#{type}:#{size}"
  end
end
