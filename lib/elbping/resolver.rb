require 'resolv'

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
      resp = []

      unless target.end_with? ".elb.amazonaws.com"
        raise ArgumentError, "Not an Amazon ELB hostname"
      end

      Timeout::timeout(timeout) do
        Resolv::DNS.open do |sysdns|
          resp = sysdns.getresources target, Resolv::DNS::Resource::IN::NS
        end
      end

      if resp.empty?
        parent = target.split(".")[1..-1].join('.')
        if parent.empty?
          raise ArgumentError, "Could not find Amazon nameserver for ELB"
        end
        find_elb_ns(parent, timeout)
      else
        resp.map { |ns| ns.name.to_s }
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

      # Resolv::DNS never completes queries successfully if you pass a list
      # of nameservers to it
      nameserver = find_elb_ns(target, timeout).sample

      Timeout::timeout(timeout) do
        Resolv::DNS.open :nameserver => nameserver do |dns|
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
