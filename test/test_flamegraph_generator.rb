# frozen_string_literal: true

require "test_helper"

class TestFlamegraphGenerator < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::FlamegraphGenerator::VERSION
  end

  def test_can_generate_flamegrapeh
    generator = FlamegraphGenerator.new
    generator.add_event(name: 'F0', start: 100, finish: 200)
    generator.add_event(name: 'F1', start: 115, finish: 140)
    generator.add_event(name: 'F2', start: 150, finish: 190)
    generator.add_event(name: 'F1', start: 160, finish: 170)
    generator.add_event(name: 'F3', start: 210, finish: 270)

    expected = {
      "$schema": "https://www.speedscope.app/file-format-schema.json",
      version: "0.0.1",
      shared: {
        frames: [
          {name: "F0", index: 0},
          {name: "F1", index: 1},
          {name: "F2", index: 2},
          {name: "F3", index: 3}
        ]
      },
      profiles: [
        {
          type: "evented",
          name: 'flamegraph', unit: 'seconds',
          startValue: 0, endValue: 170,
          events: [
            {type: "O", frame: 0, at: 0},
            {type: "O", frame: 1, at: 15},
            {type: "C", frame: 1, at: 40},
            {type: "O", frame: 2, at: 50},
            {type: "O", frame: 1, at: 60},
            {type: "C", frame: 1, at: 70},
            {type: "C", frame: 2, at: 90},
            {type: "C", frame: 0, at: 100},
            {type: "O", frame: 3, at: 110},
            {type: "C", frame: 3, at: 170}
          ]
        }
      ]
    }
    flamegraph = generator.generate_flamegraph
    assert_equal expected, flamegraph
  end

  def test_can_generate_an_empty_flamegraph
    generator = FlamegraphGenerator.new
    flamegraph = generator.generate_flamegraph

    assert_equal [], flamegraph[:shared][:frames]
    assert_equal [], flamegraph[:profiles]
  end

  def test_can_generate_flamegraph_with_different_name_and_units
    generator = FlamegraphGenerator.new(name: 'test test test', unit: 'milliseconds')
    generator.add_event(name: 'F0', start: 100, finish: 200)

    flamegraph = generator.generate_flamegraph
    profile = flamegraph[:profiles][0]

    assert_equal 'test test test', profile[:name]
    assert_equal 'milliseconds', profile[:unit]
  end

  def test_can_generate_flamegraph_with_file_line_col_info
    generator = FlamegraphGenerator.new
    generator.add_event(name: 'F0', start: 100, finish: 200, file: 'x.rb', line: 20, col: 20)
    generator.add_event(name: 'F1', start: 150, finish: 170, file: 'x.rb', line: 25, col: 10)
    generator.add_event(name: 'F1', start: 180, finish: 190, file: 'x.rb', line: 25, col: 10)
    generator.add_event(name: 'F2', start: 200, finish: 300, file: 'y.rb', line: 17, col: 32)

    flamegraph = generator.generate_flamegraph
    frames = flamegraph[:shared][:frames]

    assert_equal 3, frames.length
    assert_equal 'F0', frames[0][:name]
    assert_equal 'F1', frames[1][:name]
    assert_equal 'F2', frames[2][:name]

    assert_equal 'x.rb', frames[0][:file]
    assert_equal 'x.rb', frames[1][:file]
    assert_equal 'y.rb', frames[2][:file]

    assert_equal 20, frames[0][:line]
    assert_equal 25, frames[1][:line]
    assert_equal 17, frames[2][:line]

    assert_equal 20, frames[0][:col]
    assert_equal 10, frames[1][:col]
    assert_equal 32, frames[2][:col]
  end
end
