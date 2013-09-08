# elbping

[![Build Status](https://travis-ci.org/chooper/elbping.png?branch=master)](https://travis-ci.org/chooper/elbping)

`elbping` is a tool to ping all of the nodes that make up an Amazon Elastic
Load Balancer. It only works for ELBs in HTTP and HTTPS mode and works by
triggering an HTTP 405 (METHOD NOT ALLOWED) error caused when the ELB
receives a HTTP verb that is too long. This ensures that only the round
trip time between `elbping` and the elastic load balancer itself is
being measured.

## Installation

Installation is as easy as:

```
  $ gem install elbping
```

If you want to build a development version or your own branch or fork,
something like the following will work:

```
  $ git clone git@github.com:chooper/elbping.git
  $ cd elbping
  $ bundle install
```

## Usage

```
  $ elbping
  Usage: ./bin/elbping [options] <elb uri>
      -L, --verb-length LENGTH         Use verb LENGTH characters long (default: 128)
      -W, --timeout SECONDS            Use timeout of SECONDS for HTTP requests (default: 10)
      -w, --wait SECONDS               Wait SECONDS between pings (default: 0)
      -c, --count COUNT                Ping each node COUNT times (default: 0)
  $ elbping -c 4 http://test-elb-868888812.us-east-1.elb.amazonaws.com
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
  8 requests, 8 responses, 0% loss, 2 nodes
  min/avg/max = 188/189/192 ms
```

### Configuration

In addition to the command line arguments, `elbping` can also be
configured through the use of environment variables. The following
enviromment variables are checked and, if no command line argument
overrides it, its value is used in place of the default:

* ``PING_ELB_VERBLEN`` - Size of the HTTP verb to use when pinging an ELB
* ``PING_ELB_PINGCOUNT`` - The number of pings to send before exiting.  Zero means never quit.
* ``PING_ELB_TIMEOUT`` - The connect and read timeouts to use when sending the request to the ELB node (in seconds)
* ``PING_ELB_WAIT`` - The amount of time (in seconds) to wait between volleys of pings

Note that none of these *need* to be set as `elbping` uses some pretty
reasonable defaults. See `elbping`'s usage for more details on that.

