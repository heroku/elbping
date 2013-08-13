# ping-elb

`ping-elb` is a tool to ping all of the nodes behind an Amazon Elastic
Load Balancer. It only works for ELBs in HTTP mode and works by
triggering an HTTP 405 (METHOD NOT ALLOWED) error caused when the ELB
receives a HTTP verb that is too long.

Technically, with minor changes, you could resolve any host name and
measure the response time of each host listed in those A records but
this was designed specifically with ELBs in mind.

## TODO

* Make tool usable as a gem or whatever

## Installation

```
  $ git clone git@github.com:chooper/ping-elb.git
  $ cd ping-elb
  $ gem build ./elbping.gemspec
  $ gem install ./elbping-*.gem
```

## Usage

```
  $ elbping
  Usage: elbping [options] <elb hostname>
      -N, --nameserver NAMESERVER      Use NAMESERVER to perform DNS queries
      -L, --verb-length LENGTH         Use verb LENGTH characters long
      -W, --timeout SECONDS            Use timeout of SECONDS for HTTP requests
      -w, --wait SECONDS               Wait SECONDS between pings (default: 0)
      -c, --count COUNT                Ping each node COUNT times
  $ elbping test-elb-868888812.us-east-1.elb.amazonaws.com
  Response from 54.225.140.20: code=405 time=238 ms
  Response from 54.225.140.20: code=405 time=234 ms
  Response from 54.225.140.20: code=405 time=228 ms
  Response from 54.225.140.20: code=405 time=267 ms
  --- total statistics ---
  4 requests, 4 responses, 0% loss
  min/avg/max = 228/241/267 ms
  --- 54.225.140.20 statistics ---
  4 requests, 4 responses, 0% loss
  min/avg/max = 228/241/267 ms
```

