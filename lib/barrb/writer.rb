require 'barrb/segment'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/hash/reverse_merge'

module Barrb
  class Writer
    attr_accessor :default_interval

    def initialize(command, &block)
      @segments = []
      @output = []
      @mutex = Mutex.new
      instance_eval(&block)
      @pipe = IO.popen(command, 'w+')
      @segments.each(&:start)
      @segments.each(&:join)
    end

    def segment(options = {}, &block)
      segment = Segment.new(options.reverse_merge(default_options), &block)
      index = @segments.size
      segment.on_change do |output|
        update_output(index, output)
      end
      @segments << segment
    end

    def insert(string)
      segment(interval: :once) { string }
    end

    protected

    def update_output(segment_index, output)
      @mutex.synchronize do
        @output[segment_index] = output
        @pipe.puts @output.join
      end
    end

    def default_options
      {
        interval: default_interval || 1
      }
    end
  end
end
