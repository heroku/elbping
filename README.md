# ping-elb

`ping-elb` is a tool to ping all of the nodes behind an Amazon Elastic
Load Balancer. It only works for ELBs in HTTP mode and works by
triggering an HTTP 405 (METHOD NOT ALLOWED) error caused when the ELB
receives a HTTP verb that is too long.

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
  {:status=>:ok, :node=>"1.2.3.4", :duration=>0.226503, :checked_at=>1376014065.557045}
  {:status=>:ok, :node=>"5.6.7.8", :duration=>0.215092, :checked_at=>1376014065.7837021}
  {:status=>:ok, :node=>"9.10.11.12", :duration=>0.215337, :checked_at=>1376014065.998894}
```

The duration is a float that represents the number of seconds elapsed.
If status is not `:ok` then it means the address given returned
something other than an HTTP 405.
