#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'optparse'

require './lib/elbtool/pinger.rb'
require './lib/elbtool/resolver.rb'
require './lib/elbtool/display.rb'

$stderr.sync = true
$stdout.sync = true

# Set up default options
OPTIONS = {}
OPTIONS[:verb_len]      = ENV['PING_ELB_MAXVERBLEN']    || 128
OPTIONS[:nameserver]    = ENV['PING_ELB_NS']            || 'ns-941.amazon.com'
OPTIONS[:count]         = ENV['PING_ELB_PINGCOUNT']     || 4
OPTIONS[:timeout]       = ENV['PING_ELB_TIMEOUT']       || 10
OPTIONS[:wait]          = ENV['PING_ELB_WAIT']          || 0

# Build parser for command line options
PARSER = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] <elb hostname>"

  opts.on("-N NAMESERVER", "--nameserver NAMESERVER", "Use NAMESERVER to perform DNS queries") do |ns|
    OPTIONS[:nameserver] = ns
  end
  opts.on("-L LENGTH", "--verb-length LENGTH", Integer, "Use verb LENGTH characters long") do |n|
    OPTIONS[:verb_len] = n
  end
  opts.on("-W SECONDS", "--timeout SECONDS", Integer, "Use timeout of SECONDS for HTTP requests") do |n|
    OPTIONS[:timeout] = n
  end
  opts.on("-w SECONDS", "--wait SECONDS", Integer, "Wait SECONDS between pings (default: 0)") do |n|
    OPTIONS[:wait] = n
  end
  opts.on("-c COUNT", "--count COUNT", Integer, "Ping each node COUNT times") do |n|
    OPTIONS[:count] = n
  end
end

# Parse options
def usage
  puts PARSER.help
  exit(false)
end
PARSER.parse!(ARGV) rescue usage

# Main entry point of the program
def main
  if ARGV.size < 1
    usage
  end

  target = ARGV[0]
  nodes = ElbTool::Resolver.find_elb_nodes(target, OPTIONS[:nameserver])

  # Set up summary objects
  total_summary = {
    :reqs_attempted =>  0,
    :reqs_completed =>  0,
    :latencies      => [],
  }
  node_summary = {}
  nodes.each { |node| node_summary[node] = total_summary.clone }

  # Catch ctrl-c
  trap("INT") {
    ElbTool::Display.summary(total_summary, node_summary)
    exit
  }

  (1..OPTIONS[:count]).each { |i|
    sleep OPTIONS[:wait] if i > 1

    nodes.map { |node|
      total_summary[:reqs_attempted] += 1
      node_summary[node][:reqs_attempted] += 1
      status = ElbTool::HttpPinger.ping_node(node, OPTIONS[:verb_len], OPTIONS[:timeout])

      unless status[:code] == :timeout
        total_summary[:reqs_completed] += 1
        total_summary[:latencies] += [status[:duration]]
        node_summary[node][:reqs_completed] += 1
        node_summary[node][:latencies] += [status[:duration]]
      end

      ElbTool::Display.response(status)
    }
  }
  ElbTool::Display.summary(total_summary, node_summary)
end

main

