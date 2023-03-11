# frozen_string_literal: true

require 'json'
require 'rainbow'

module Tasks
  module Contracts
    def self.fix(raw_json)
      examples = JSON.parse(raw_json)['examples'].filter do |example|
        example['status'] == 'failed'
      end.map do |raw|
        parse(raw)
      end.filter do |failure|
        failure[:expected].size == 64
      end

      examples.each do |example|
        fix!(example, preview: false)
      end

      puts "Done! #{examples.size} tests updated."
    end

    def self.fix!(example, preview:)
      lines = File.read(example[:file]).split("\n")

      line = example[:line]

      line -= 1 while line > 0 && lines[line] !~ /#{example[:expected]}/

      if line == 0
        puts "\n#{example[:file]}:#{line} | #{Rainbow('Contract not found.').red}"
        return
      end

      puts "\n"
      puts "#{example[:file]}:#{line}"
      puts "  #{Rainbow('from:').yellow} #{lines[line].sub(example[:expected], Rainbow(example[:expected]).red).strip}"
      lines[line] = lines[line].sub(example[:expected], example[:got])
      puts "    #{Rainbow('to:').yellow} #{lines[line].sub(example[:got], Rainbow(example[:got]).blue).strip}"

      return if preview

      File.write(example[:file], lines.join("\n"))
    end

    def self.parse(example)
      mismatch = example['exception']['message'].split("\n")
      got = mismatch.find { |line| line =~ /got:/ }.to_s.sub(/.*got: "/, '').sub('"', '')
      expected = mismatch.find { |line| line =~ /expected:/ }.to_s.sub(/.*expected: "/, '').sub('"', '')

      failure_line = example['exception']['backtrace'].find do |location|
        location =~ %r{lighstorm/spec/} && location !~ %r{lighstorm/spec/helpers/}
      end.to_s.split('.rb:').last.to_s.split(':').first.to_i

      {
        expected: expected,
        got: got,
        file: example['file_path'],
        line: failure_line
      }
    end
  end
end
