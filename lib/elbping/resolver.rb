
require 'resolv'

# TODO: Raise own exceptions

module ElbPing
  # Handles all DNS resolution and, more specifically, ELB node discovery
  module Resolver

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

      Timeout::timeout(timeout) do 
        Resolv::DNS.open do |sysdns|
          resp = sysdns.getresources "all." + target, Resolv::DNS::Resource::IN::A
        end
      end

      if resp
        resp.select { |r| r.respond_to? "address" and r.address }.map { |r| r.address.to_s  }
      end
    end
  end
end
