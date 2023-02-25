# frozen_string_literal: true

require 'securerandom'

require 'digest'

require 'fileutils'

require_relative './sanitizer/safe'
require_relative './sanitizer/unsafe'

module Sanitizer
  DEVELOPMENT_MODE = true

  def self.protect(data)
    protected_data = apply(Marshal.load(Marshal.dump(data)))
  rescue StandardError => e
    raise e unless DEVELOPMENT_MODE

    paths = build_paths(Marshal.load(Marshal.dump(data)))
    config = {}
    paths.each do |key|
      config[key] = true unless SAFE.key?(key) || UNSAFE.key?(key)
    end
    pp config

    puts e.message
    exit!
  end

  def self.build_paths(node, path = [], paths = [])
    case node
    when Hash
      result = {}
      node.each_key do |key|
        result[key] = build_paths(node[key], path.dup.push(key), paths)
      end
    when Array
      result = []
      node.each do |value|
        result << build_paths(value, path.dup.push('[]'), paths)
      end
    else
      paths << path_to_key(path.dup)
    end

    paths
  end

  def self.apply(node, path = [])
    case node
    when Hash
      result = {}
      node.each_key do |key|
        result[key] = apply(node[key], path.dup.push(key))
      end
    when Array
      result = []
      node.each do |value|
        result << apply(value, path.dup.push('[]'))
      end
    else
      result = safe_value(node, path.dup)
    end

    result
  end

  def self.path_to_key(path)
    parts = path.join('/')
                .sub(%r{/\d+/}, '/[]/')
                .sub(%r{/\d+$}, '/[]')
                .sub(%r{^\d/}, '[]/')
                .sub(%r{/\w{30,}/}, '/{}/')
                .sub(%r{/\w{30,}$}, '/{}')
                .sub(%r{^\w{30,}/}, '{}/')

    parts = parts.gsub('[]', '').gsub('{}', '').gsub(%r{/+}, '/')

    parts = parts.split('/').reject(&:empty?)

    parts = parts[parts.size - 2..parts.size] if parts.size > 2

    key = parts.reverse.join(' <= ')

    if key =~ /\{\}/ || key =~ /\[\]/
      raise "unexpected key '#{key}'" unless DEVELOPMENT_MODE

      puts "unexpected key '#{key}'"
      puts path.inspect
      exit!

    end

    key
  end

  def self.safe_value(value, path)
    key = path_to_key(path)

    raise "missing safety definitions for '#{key}'" unless SAFE.key?(key) || UNSAFE.key?(key)

    return value if SAFE[key]

    obfuscate(value)
  end

  def self.obfuscate(value)
    case value
    when String
      obfuscate_string(value)
    when Symbol
      obfuscate_string(value.to_s).to_sym
    when Float
      obfuscate_float(value)
    when Integer
      obfuscate_integer(value)
    when TrueClass, FalseClass, NilClass, Time, GRPC::Unknown, GRPC::NotFound
      value
    else
      raise "missing obfuscator for #{value.class} #{value}"
    end
  end

  def self.obfuscate_string(value)
    pack = value.encoding.name == 'ASCII-8BIT'

    obfuscated = value
    obfuscated = obfuscated.unpack1('H*') if pack

    size = obfuscated.size

    obfuscated = SecureRandom.hex(obfuscated.size)[0..size - 1]

    raise "unexpected obfuscated size #{obfuscated.size} != #{size}" if obfuscated.size != size

    obfuscated = [obfuscated].pack('H*') if pack
    obfuscated
  end

  def self.obfuscate_integer(value)
    obfuscated = value

    size = obfuscated.to_s.size

    obfuscated = ''

    size.times do |i|
      obfuscated += if [0, (size - 1)].include?(i)
                      rand(1..9).to_s
                    else
                      rand(0..9).to_s
                    end
    end

    obfuscated = obfuscated.to_i

    raise "unexpected obfuscated size #{obfuscated.to_s.size} != #{size}" if obfuscated.to_s.size != size

    obfuscated
  end

  def self.obfuscate_float(value)
    size = value.to_s.size

    obfuscated = value.to_s.split('.').map { |v| obfuscate_integer(v) }.join('.').to_f

    raise "unexpected obfuscated size #{obfuscated.to_s.size} != #{size}" if obfuscated.to_s.size != size

    obfuscated
  end
end
