
require 'resolv'

# A TCP-only resolver built from `Resolv::DNS`. See the docs for what it's about.
# http://ruby-doc.org/stdlib-1.9.3/libdoc/resolv/rdoc/Resolv/DNS.html
class TcpDNS < Resolv::DNS
  # Override fetch_resource to use a TCP requester instead of a UDP requester. This
  # is mostly borrowed from `lib/resolv.rb` with the UDP->TCP fallback logic removed.
  def fetch_resource(name, typeclass)
    lazy_initialize
    request = make_tcp_requester
    sends = {}
    begin
      @config.resolv(name) { |candidate, tout, nameserver, port|
        msg = Message.new
        msg.rd = 1
        msg.add_question(candidate, typeclass)
        unless sender = senders[[candidate, nameserver, port]]
          sender = senders[[candidate, nameserver, port]] =
            requester.sender(msg, candidate, nameserver, port)
        end
        reply, reply_name = requester.request(sender, tout)
        case reply.rcode
        when RCode::NoError
          yield(reply, reply_name)
          return
        when RCode::NXDomain
          raise Config::NXDomain.new(reply_name.to_s)
        else
          raise Config::OtherResolvError.new(reply_name.to_s)
        end
      }
    ensure
      requester.close
    end
  end
end

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
