
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
          ns = target.split(".")[1..-1].join('.')
          resp = sysdns.getresources ns, Resolv::DNS::Resource::IN::NS
          unless resp
            raise ArgumentError, "Could not find Amazon nameserver for ELB"
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
      raise ArgumentError, "Could not query DNS" if target.nil?

      resp = nil

      unless target.end_with? ".elb.amazonaws.com"
        Timeout::timeout(timeout) do 
          Resolv::DNS.open do |sysdns|
            resp = sysdns.getresources target, Resolv::DNS::Resource::IN::CNAME
            cname = resp[0].name.to_s if resp and resp.size > 0
            return find_elb_nodes(cname, timeout)
          end
        end
      end

      nameservers = find_elb_ns target, timeout

      Timeout::timeout(timeout) do
        TcpDNS.open :nameserver => nameservers, :search => '', :ndots => 1 do |dns|
          # TODO: Exceptions
          resp = dns.getresources "all.#{target}", Resolv::DNS::Resource::IN::A
        end
      end
      if resp
        resp.select { |r| r.respond_to? "address" and r.address }.map { |r| r.address.to_s  }
      end
    end
  end
end
