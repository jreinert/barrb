module Barrb
  class Segment
    attr_writer :on_change

    def initialize(options, &block)
      @options = options
      output_loop(&block) if block_given?
    end

    def on_change(&block)
      @on_change = block
    end

    def output_loop(&block)
      @output_loop = block
    end

    def start
      @loop_thread = Thread.new do
        catch(:stop) { run }
      end
    end

    def stop
      @should_stop = true
    end

    def join
      @loop_thread.join
    end

    protected

    def should_stop?
      @should_stop
    end

    def loop_output
      @output_loop.call
    end

    def notify_change(output)
      @on_change.call(output)
      @last_output = output
    end

    def time
      started = Time.now
      yield
      Time.now - started
    end

    def process_loop
      time do
        output = loop_output
        notify_change(output) if @last_output != output
      end
    end

    def run
      loop do
        break if should_stop?
        execution_time = time { process_loop }
        break if @options[:interval] == :once
        next if execution_time >= @options[:interval]
        sleep(@options[:interval] - execution_time)
      end
    end
  end
end
