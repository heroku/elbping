
require 'resolv'

class TcpDNS < Resolv::DNS
  # This is largely a copy-paste job from mri/source/lib/resolv.rb
  # with some of the UDP->TCP fallback logic removed
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
  module Resolver
    # Resolve an ELB address to a list of node IPs. Should always return a list
    # as long as the server responded, even if it's empty.
    def self.find_elb_nodes(target, nameservers, timeout=5)
      # `timeout` is in seconds
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

