Gem::Specification.new do |s|
  s.name        = 'elbping'
  s.version     = '0.0.8'
  s.date        = '2013-08-13'
  s.summary     = "Small tool to 'ping' the nodes that make up an Amazon Elastic Load Balancer"
  s.description = "elbping is a tool to ping all of the nodes behind an Amazon Elastic Load Balancer. It only works for ELBs in HTTP mode and works by triggering an HTTP 405 (METHOD NOT ALLOWED) error caused when the ELB receives a HTTP verb that is too long."
  s.authors     = ["Charles Hooper"]
  s.email       = 'chooper@plumata.com'
  s.files       = ["lib/elbping/cli.rb",
                  "lib/elbping/display.rb",
                  "lib/elbping/pinger.rb",
                  "lib/elbping/resolver.rb"]
  s.executables << "elbping"
  s.require_paths = ["lib"]

  s.add_dependency "net-dns", "~> 0.8.0"

  s.homepage    =
    'https://github.com/chooper/elbping'
  s.license       = 'MIT'
end
