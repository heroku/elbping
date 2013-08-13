
require 'net/dns'

module ElbPing
  module Resolver
    # Resolve an ELB address to a list of node IPs
    def self.find_elb_nodes(target, nameserver)

      # First resolve our nameserver IP
      ns_addrs = Resolver(nameserver).answer.map { |rr| rr.address.to_s }

      # Now resolve our ELB nodes
      resolver = Net::DNS::Resolver.new(
        :use_tcp => true,
        :nameservers => ns_addrs,
        :retry => 5)

      resp = resolver.query(target, Net::DNS::ANY)

      nodes = []
      resp.each_address { |a| nodes += [a.to_s] }
      nodes
    end
  end
end

