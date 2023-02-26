# frozen_string_literal: true

require 'fileutils'
require 'babosa'
require 'digest'

# Inspired by https://github.com/vcr/vcr
module VCR
  RECORDER = Struct.new(:kind) do
    def replay(key, *params, &block)
      VCR.replay(key, *params, kind: kind, &block)
    end

    def replay!(key, *params, &block)
      VCR.replay(key, *params, kind: kind, &block)
    end
  end

  TAPE = RECORDER.new(:tapes)
  REEL = RECORDER.new(:reels)

  def self.tape
    TAPE
  end

  def self.reel
    REEL
  end

  def self.replay(key, params = {}, kind:, &block)
    path = build_path_for(key, params, kind: kind)

    return Marshal.load(File.read(path)) if File.exist?(path)

    response = block.call

    FileUtils.mkdir_p(File.dirname(path))

    protected_response = Sanitizer.protect(response)

    File.write(path, Marshal.dump(protected_response))

    protected_response
  end

  def self.replay!(key, params = {}, kind:, &block)
    path = build_path_forr(key, params, kind: kind)

    FileUtils.rm_f(path)

    replay(key, params, &block)
  end

  def self.build_path_for(key, params, kind: :tapes, partial: false)
    if params.size.positive?
      key_params = []
      params.keys.sort.each do |param_key|
        key_params << if params[param_key].is_a?(Hash)
                        "#{param_key}#{build_path_for('', params[param_key], kind: kind, partial: true)}"
                      else
                        "#{param_key}/#{params[param_key]}"
                      end
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

    return path.join('/') if partial

    "spec/data/#{kind}/#{path.join('/')}.bin"
  end
end
