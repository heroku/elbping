
require 'net/dns'
require 'ipaddress'

module ElbPing
  module Resolver
    def self.resolve_ns(nameserver)
      # Resolve nameserver IP (you can't just plug a hostname into Net::DNS::Resolve)
      # Return an empty list if can't look up nameserver address
      if IPAddress.valid? nameserver
        ns_addrs = [nameserver]
      else
        begin
          ns_addrs = Resolver(nameserver).answer.map { |rr| rr.address.to_s }
        rescue
          ns_addrs = []
        end
      end
    end

    # Resolve an ELB address to a list of node IPs. Should always return a list
    # as long as the server responded, even if it's empty.
    def self.find_elb_nodes(target, nameserver)
      ns_addrs = resolve_ns nameserver

      # Now resolve our ELB nodes
      resolver = Net::DNS::Resolver.new(
        :use_tcp => true,
        :nameservers => ns_addrs,
        :retry => 5)
      begin
        resp = resolver.query(target, Net::DNS::ANY)
      rescue Net::DNS::Resolver::Error, ArgumentError
        # For some reason ArgumentError is raised on timeout in OSX
        raise "Error querying DNS: Probably a timeout"
      end

      nodes = []
      resp.each_address { |a| nodes += [a.to_s] }
      nodes
    end
  end
end

