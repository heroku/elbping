# ping-elb

`ping-elb` is a tool to ping all of the nodes behind an Amazon Elastic
Load Balancer. It only works for ELBs in HTTP mode and works by
triggering an HTTP 405 (METHOD NOT ALLOWED) error caused when the ELB
receives a HTTP verb that is too long.

Technically, with minor changes, you could resolve any host name and
measure the response time of each host listed in those A records but
this was designed specifically with ELBs in mind.

## Installation

```
  $ git clone git@github.com:chooper/ping-elb.git
  $ cd ping-elb
  $ bundle install
```

## Usage

```
  $ ./ping-elb.rb
  Usage: ./ping-elb.rb <elb_hostname>
  $ ./ping-elb.rb elb01234-5678910.us-east-1.elb.amazonaws.com
  Response from 1.1.1.1: code=405 time=190 ms
  Response from 2.2.2.2: code=405 time=192 ms
  Response from 1.1.1.1: code=405 time=196 ms
  Response from 2.2.2.2: code=405 time=192 ms
  Response from 1.1.1.1: code=405 time=196 ms
  Response from 2.2.2.2: code=405 time=192 ms
  Response from 1.1.1.1: code=405 time=196 ms
  Response from 2.2.2.2: code=405 time=192 ms
```

