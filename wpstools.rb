#!/usr/bin/env ruby
# encoding: UTF-8

$: << '.'
require File.dirname(__FILE__) + '/lib/wpstools/wpstools_helper'

begin

  banner()

  option_parser = CustomOptionParser.new('Usage: ./wpstools.rb [options]', 60)
  option_parser.separator ''
  option_parser.add(['-v', '--verbose', 'Verbose output'])

  plugins = Plugins.new(option_parser)
  plugins.register(
    CheckerPlugin.new,
    ListGeneratorPlugin.new,
    StatsPlugin.new
  )

  options = option_parser.results

  if options.empty?
    raise "No option supplied\n\n#{option_parser}"
  end

  plugins.each do |plugin|
    plugin.run(options)
  end

rescue => e
  puts "[ERROR] #{e.message}"
  puts 'Trace :'
  puts e.backtrace.join("\n")
end
