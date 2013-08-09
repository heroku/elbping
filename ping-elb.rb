#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'net/dns'
require "net/http"

MAX_VERB_LENGTH = 127
NAMESERVERS = '204.246.160.5' # ns-941.amazon.com
DEBUG = false

class ElbPing < Net::HTTPRequest
  METHOD = "A" * (MAX_VERB_LENGTH + 1)
  REQUEST_HAS_BODY = false
  RESPONSE_HAS_BODY = false
end

def ping_node(node, port=80, path="/")
  start = Time.now.getutc
  http = Net::HTTP.new(node, port.to_s)
  response = http.request(ElbPing.new(path))
  status = 'ok' unless response.code == 405 rescue 'badcode'

  {:status => status.to_sym,
    :node => node,
    :duration => (Time.now.getutc - start),
    :checked_at => start.to_f}
end

def find_elb_nodes(target)
  resolver = Net::DNS::Resolver.new(
    :use_tcp => true,
    :nameservers => NAMESERVERS,
    :retry => 5)

  if DEBUG
    resolver.log_level = Net::DNS::DEBUG
  end

  resp = resolver.query(target, Net::DNS::ANY)

  nodes = []
  resp.each_address { |a| nodes += [a.to_s] }
  nodes
end

if ARGV.size < 1
  puts "Usage: #{$0} <elb_hostname>"
  exit(false)
end

target = ARGV[0]
nodes = find_elb_nodes(target)
nodes.map { |node| puts ping_node(node) }

