Gem::Specification.new do |s|
  s.name          = 'elbping'
  s.version       = '0.1'
  s.date          = '2013-08-13'
  s.summary       = "Small tool to 'ping' the nodes that make up an Amazon Elastic Load Balancer"
  s.description   = "elbping is a tool to ping all of the nodes behind an Amazon Elastic Load Balancer. It only works for ELBs in HTTP mode and works by triggering an HTTP 405 (METHOD NOT ALLOWED) error caused when the ELB receives a HTTP verb that is too long."
  s.authors       = ["Charles Hooper"]
  s.email         = 'chooper@plumata.com'
  s.homepage      = 'https://github.com/chooper/elbping'
  s.license       = 'MIT'

  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_development_dependency "rake", "~> 10.0.4"

  s.homepage    =
    'https://github.com/chooper/elbping'
  s.license       = 'MIT'
end
