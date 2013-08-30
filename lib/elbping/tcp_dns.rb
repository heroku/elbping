
require 'resolv'

# A TCP-only resolver built from `Resolv::DNS`. See the docs for what it's about.
# http://ruby-doc.org/stdlib-1.9.3/libdoc/resolv/rdoc/Resolv/DNS.html
class TcpDNS < Resolv::DNS
  # Override fetch_resource to use a TCP requester instead of a UDP requester. This
  # is mostly borrowed from `lib/resolv.rb` with the UDP->TCP fallback logic removed.
  def each_resource(name, typeclass, &proc)
    lazy_initialize
    senders = {}
    requester = nil
    begin
      @config.resolv(name) { |candidate, tout, nameserver, port|
        requester = make_tcp_requester(nameserver, port)
        msg = Message.new
        msg.rd = 1
        msg.add_question(candidate, typeclass)
        unless sender = senders[[candidate, nameserver, port]]
          sender = senders[[candidate, nameserver, port]] =
            requester.sender(msg, candidate, nameserver, port)
        end

        begin # HACK
          reply, reply_name = requester.request(sender, tout)
        rescue
          return
        end

        case reply.rcode
        when RCode::NoError
          extract_resources(reply, reply_name, typeclass, &proc)
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
