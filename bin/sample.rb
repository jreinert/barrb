#!/usr/bin/env ruby

require 'barrb'

Barrb::Writer.new('dzen2 -ta r') do
  segment interval: 1.minute do
    Time.now.strftime('%H:%M')
  end

  insert ' | '

  segment interval: 5.seconds do
    Time.now.strftime('%H:%M:%S')
  end

  insert ' | '

  scroll_segment interval: :once, width: 20 do
    'A very long string that needs some scrolling'
  end
end
