# frozen_string_literal: true

module TestData
  class Monitor
    include Singleton

    attr_reader :accessed_files

    def reboot!
      @accessed_files = {}
    end

    def register_access!(path)
      @accessed_files[path] = true
    end
  end

  def self.read(path)
    Monitor.instance.register_access!(path)
    File.read(path)
  end
end
