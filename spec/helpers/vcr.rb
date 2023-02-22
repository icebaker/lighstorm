# frozen_string_literal: true

require 'fileutils'
require 'babosa'
require 'digest'

# Inspired by https://github.com/vcr/vcr
module VCR
  def self.replay(key, params = {}, &block)
    path = build_path_for(key, params)

    return Marshal.load(File.read(path)) if File.exist?(path)

    response = block.call

    FileUtils.mkdir_p(File.dirname(path))

    protected_response = Sanitizer.protect(response)

    File.write(path, Marshal.dump(protected_response))

    protected_response
  end

  def self.replay!(key, params = {}, &block)
    path = build_path_for(key, params)

    FileUtils.rm_f(path)

    replay(key, params, &block)
  end

  def self.build_path_for(key, params)
    if params.size.positive?
      key_params = []
      params.keys.sort.each do |param_key|
        key_params << "#{param_key}/#{params[param_key]}"
      end

      path = "#{key}/#{key_params.sort.join('/')}"
    else
      path = key
    end

    path = path.gsub('.', '/').gsub('::', '/').split('/').map do |part|
      part.to_slug.normalize.to_s
    end.map do |item|
      item.size > 64 ? [item[0..64], Digest::SHA256.hexdigest(item)] : item
    end.flatten

    "spec/data/tapes/#{path.join('/')}.bin"
  end
end
