
require 'resolv'
require 'elbping/tcp_dns.rb'

module ElbPing
  # Handles all DNS resolution and, more specifically, ELB node discovery
  module Resolver

    # Resolve an ELB address to a list of node IPs. Should always return a list
    # as long as the server responded, even if it's empty.
    #
    # Arguments:
    #   target: (string)
    #   nameservers: (array) of strings
    #   timeout: (fixnum)
    #
    # Could raise:
    # * Timeout::Error
    # * ?

    def self.find_elb_nodes(target, nameservers, timeout=5)
      resp = nil
      Timeout::timeout(timeout) do 
        TcpDNS.open :nameserver => nameservers, :search => '', :ndots => 1 do |dns|
          # TODO: Exceptions
          resp = dns.getresources target, Resolv::DNS::Resource::IN::A
        end
      end
      resp.map { |r| r.address.to_s }
    end
  end
end
