# frozen_string_literal: true

require 'json'
require_relative "flamegraph_generator/version"

class FlamegraphGenerator
  Event = Struct.new(:name, :start, :finish, :file, :line, :col, keyword_init: true)

  def initialize(name: 'flamegraph', unit: 'seconds')
    @name = name
    @unit = unit
    @events = []
  end

  def add_event(name:, start:, finish:, file: nil, line: nil, col: nil)
    raise ArgumentError, "name is required" unless name
    raise ArgumentError, "start must be of type Numeric" unless start.is_a?(Numeric)
    raise ArgumentError, "finish must be of type Numeric" unless finish.is_a?(Numeric)

    @events << Event.new(name: name, start: start, finish: finish, file: file, line: line, col: col)
  end

  def save(path:, open: true)
    File.write(path, generate_flamegraph.to_json)
    open_with_speedscope(path) if open
  end

  def generate_flamegraph
    sorted_events = @events.sort_by { |event| [event.start, event.finish] }

    frames_by_name = {}
    frames = sorted_events.uniq(&:name).map.with_index do |event, index|
      frame = { name: event.name, file: event.file, line: event.line, col: event.col, index: index }.compact
      frames_by_name[event.name] = frame
      frame
    end

    start= sorted_events.first&.start
    finish = sorted_events.max_by { |event| event.finish }&.finish

    speedscope_events = sorted_events.map do |event|
      frame_index = frames_by_name[event.name][:index]
      [
        { "type": 'O', "frame": frame_index, at: event.start - start },
        { "type": 'C', "frame": frame_index, at: event.finish - start }
      ]
    end.flatten.sort_by { |speedscope_event| speedscope_event[:at] }

    {
      "$schema":  'https://www.speedscope.app/file-format-schema.json',
      version:  '0.0.1',
      shared:   { frames: frames },
      profiles: [({
        type:       'evented',
        name:       @name,
        unit:       @unit,
        startValue: 0,
        endValue:   finish - start,
        events:     speedscope_events,
      } if speedscope_events.present?)].compact
    }
  end

  private
    def open_with_speedscope(path)
      system("npx speedscope #{path}")
    end
end
