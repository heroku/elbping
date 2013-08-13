# elbping

`elbping` is a tool to ping all of the nodes behind an Amazon Elastic
Load Balancer. It only works for ELBs in HTTP mode and works by
triggering an HTTP 405 (METHOD NOT ALLOWED) error caused when the ELB
receives a HTTP verb that is too long.

Technically, with minor changes, you could resolve any host name and
measure the response time of each host listed in those A records but
this was designed specifically with ELBs in mind.

## Installation

Installation is as easy as:

```
  $ gem install elbping
  Successfully installed elbping-0.0.2
  1 gem installed
  Installing ri documentation for elbping-0.0.2...
  Installing RDoc documentation for elbping-0.0.2...
```

If you want to build a development version or your own branch or fork,
something like the following will work:

```
  $ git clone git@github.com:chooper/elbping.git
  $ cd elbping
  $ gem build ./elbping.gemspec
  $ gem install ./elbping-*.gem
```

## Usage

```
  $ elbping
  Usage: elbping [options] <elb hostname>
      -N, --nameserver NAMESERVER      Use NAMESERVER to perform DNS queries (default: ns-941.amazon.com)
      -L, --verb-length LENGTH         Use verb LENGTH characters long (default: 128)
      -W, --timeout SECONDS            Use timeout of SECONDS for HTTP requests (default: 10)
      -w, --wait SECONDS               Wait SECONDS between pings (default: 0)
      -c, --count COUNT                Ping each node COUNT times (default: 0)
  $ elbping -c 4 test-elb-868888812.us-east-1.elb.amazonaws.com
  Response from 54.243.63.96: code=405 time=210 ms
  Response from 23.21.73.53: code=405 time=189 ms
  Response from 54.243.63.96: code=405 time=191 ms
  Response from 23.21.73.53: code=405 time=188 ms
  Response from 54.243.63.96: code=405 time=190 ms
  Response from 23.21.73.53: code=405 time=192 ms
  Response from 54.243.63.96: code=405 time=187 ms
  Response from 23.21.73.53: code=405 time=189 ms
  --- 54.243.63.96 statistics ---
  4 requests, 4 responses, 0% loss
  min/avg/max = 187/163/210 ms
  --- 23.21.73.53 statistics ---
  4 requests, 4 responses, 0% loss
  min/avg/max = 188/189/192 ms
  --- total statistics ---
  4 requests, 4 responses, 0% loss
  min/avg/max = 188/189/192 ms
```

