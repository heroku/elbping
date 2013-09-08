
require 'resolv'
require 'elbping/tcp_dns.rb'

# TODO: Raise own exceptions

module ElbPing
  # Handles all DNS resolution and, more specifically, ELB node discovery
  module Resolver

    # Find addresses authoritative DNS server
    #
    # Arguments:
    #   target: (string) ELB hostname
    #   timeout: (fixnum) in seconds
    #
    # Could raise:
    # * Timeout::Error
    # * ArgumentError

    def self.find_elb_ns(target, timeout=5)
      resp = nil

      unless target.end_with? ".elb.amazonaws.com"
        raise ArgumentError, "Not an Amazon ELB hostname"
      end

      Timeout::timeout(timeout) do
        Resolv::DNS.open do |sysdns|
          resp = sysdns.getresources target, Resolv::DNS::Resource::IN::NS
          unless resp
            raise "Could not find Amazon nameserver for ELB"
          end
        end
        nameservers = resp.map { |ns| ns.name.to_s }
      end
    end

    # Resolve an ELB address to a list of node IPs. Should always return a list
    # as long as the server responded, even if it's empty.
    #
    # Arguments:
    #   target: (string)
    #   timeout: (fixnum)
    #
    # Could raise:
    # * Timeout::Error
    # * ArgumentError

    def self.find_elb_nodes(target, timeout=5)
      resp = nil

      nameservers = find_elb_ns target, timeout

      Timeout::timeout(timeout) do 
        TcpDNS.open :nameserver => nameservers, :search => '', :ndots => 1 do |dns|
          # TODO: Exceptions
          resp = dns.getresources target, Resolv::DNS::Resource::IN::ANY
        end
      end
      if resp
        resp.select { |r| r.respond_to? "address" and r.address }.map { |r| r.address.to_s  }
      end
    end
  end
end
