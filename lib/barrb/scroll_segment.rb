require 'barrb/segment'

module Barrb
  class ScrollSegment < Segment
    protected

    def process_loop
      started = Time.now
      output = loop_output
      @scroll_position = 0 if output != @last_output
      while @options[:interval] == :once ||
            Time.now - started < @options[:interval]
        scroll(output)
      end
      @options[:interval]
    end

    def scroll(output)
      padded_output = output + ' ' * @options[:scroll_gap]
      notify_change(scrolled_view(padded_output))
      if output.length > @options[:width]
        new_position = @scroll_position + @options[:scroll_step]
        @scroll_position = new_position % padded_output.length
      end
      sleep(0.5)#@options[:scroll_speed])
    end

    def scrolled_view(output)
      end_index = @scroll_position + @options[:width] - 1
      (output + output)[@scroll_position..end_index]
    end
  end
end
