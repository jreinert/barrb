require 'barrb/segment'
require 'barrb/scroll_segment'
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
      register_segment(
        Segment.new(options.reverse_merge(default_segment_options), &block)
      )
    end

    def scroll_segment(options = {}, &block)
      register_segment(
        ScrollSegment.new(
          options.reverse_merge(default_scroll_segment_options), &block
        )
      )
    end

    def insert(string)
      segment(interval: :once) { string }
    end

    protected

    def register_segment(segment)
      index = @segments.size
      segment.on_change do |output|
        update_output(index, output)
      end
      @segments << segment
    end

    def update_output(segment_index, output)
      @mutex.synchronize do
        @output[segment_index] = output
        @pipe.puts @output.join
      end
    end

    def default_segment_options
      {
        interval: default_interval || 1
      }
    end

    def default_scroll_segment_options
      default_segment_options.merge(
        scroll_speed: 1,
        scroll_step: 1,
        width: 40,
        scroll_gap: 4
      )
    end
  end
end
