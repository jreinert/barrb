module Barrb
  class Segment
    attr_writer :on_change

    def initialize(options, &block)
      @interval = options[:interval]
      output_loop(&block) if block_given?
    end

    def on_change(&block)
      @on_change = block
    end

    def output_loop(&block)
      @output_loop = block
    end

    def start
      @loop_thread = Thread.new(&method(:run))
    end

    def stop
      @should_stop = true
    end

    def join
      @loop_thread.join
    end

    private

    def should_stop?
      @should_stop
    end

    def run_loop_and_notify
      throw(:stop) if should_stop?
      output = @output_loop.call
      @on_change.call(output) if @last_output != output
      @last_output = output
    end

    def run
      catch(:stop) do
        loop do
          started = Time.now
          run_loop_and_notify
          break if @interval == :once
          execution_time = Time.now - started
          sleep(@interval - execution_time) if execution_time < @interval
        end
      end
    end
  end
end
