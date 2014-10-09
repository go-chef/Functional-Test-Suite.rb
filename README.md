## GoIardi Functional Test Suite

An RSpec based test suite to verify [goiardi](http://goiardi.readthedocs.org/en/latest/index.html) with
standard [knife](https://docs.getchef.com/knife.html) commands.

This test suite uses [unprivileged LXC](https://www.stgraber.org/2014/01/17/lxc-1-0-unprivileged-containers/)
for setting up _goiardi_ server in a dedicated container, and testing bootstrapping and chef runs against
the goiardi server from seperate containers.

### Setup
- We recommend setting up a ubuntu 14.04 instance for testing, which support unprivileged LXC out of the box.
- Install LXC, build essential and other development libraries
```sh
apt-get install liblxc1 lxc lxc-dev lxc-templates python3-lxc cgmanager-utils build-essential
```
- Install ruby and bundler either via apt or via rbenv/ruby-build, anything above ruby 1.8.7 should work fine.
- Run bundle install
``sh
bundle install --path
``
- Invoke the test suite
```ruby
bundle exec rake spec
```

A working example of setting up unprivileged LXC via chef can be found [here](https://github.com/GoatOS/base/blob/master/cookbooks/goatos/recipes/lxc_install.rb), you can use [GoatOS Base][https://github.com/GoatOS/base] as well if you want a generic LXC based cookbook testing framework.


### How the tests work
As part of the test suite following is done in chronological order:
- goiardi is installed in a fresh ubuntu 14.04 container using chef
- admin and validation keys are copied over from goiardi container to host system
- a series of knife CRUD operations on chef domain objects (client, node, cookbooks, databags etc) is performed against the goiardi server
- 3 more containers are created, bootstrapped using knife against the goiardi server
- cookbooks involving search is applied against the new container/chef nodes, and assetions are made against search outcomes (files).
