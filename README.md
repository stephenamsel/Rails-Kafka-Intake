# Pre-Alpha

This is still under initial design and development. 
As it is not currently being proposed for any Production use, this Gem is untested, subject to change and unpublished. Tests will
be added and the Gem will be published when the author either has a need to do so, or time to fully develop this tool. 

# Kafka Intake

The Kafka Intake Gem is meant to allow Rails to take in messages over Kafka and process them like HTTP requests. This should allow developers to build their servers normally, using Request handlers with all of MVC conventions and tools. It should also permit
easy transition from normal use of a Rails server to be used over Kafka.

The Gem is one half of a system to address concurrency problems in Rails. A well-known issue of Rails servers is that as they run concurrent requests on separate threads, they use a thread-pool to avoid high overhead from thread-management. This sets a hard limit on their numbers of requests processed concurrently even if they do not really tie up computing resources. Paired with a proxy-server that handles concurrency better than Rails and writes to Kafka, this should alleviate that problem for high-throughput endpoints by replacing Thread-management with Ruby Ractor-management while reducing network-traffic on Rails' host-machine. 

It has two expected side-effects:
1. Atomicity of database contacts is handled through savepoints rather than separate commits so database-performance
should also improve.
2. As it would requests and responses run over Kafka, other tools like ElasticSearch and Apache Druid may be connected to Kafka for unified logging and other benefits of Event Driven Design.

An example of such a proxy server (written in GoLang, known for its excellent handling of concurrency) is available under /example-proxy.

## Installation

NOTE: This gem is not published. Use only by specifying the gem-source in your Gemfile, and also at your own risk!
Install the gem and add to the application's Gemfile by executing:

    $ bundle add kafka_intake

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install kafka_intake

## Usage

1. Raise a Kafka Message Server
2. Raise a Proxy-server that populates Kafka topics and consumes corresponding messages as done by the one in /example-proxy.
You may wish to implement Authentication either in the Proxy or an API Gateway in front of that. You may also wish to limit the URIs that
reach or are forwarded by it as required by your application. Varnish and other similar tools should be usable normally as well.
3. Install the Gem in your Rails server. Build your Rails server normally.
4. Direct incoming traffic on high-throughput endpoints to your proxy server.

## Development

### This is not reqdy for collaboration yet
The author does not yet have time to devote to the Gem and management of development.

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kafka_intake. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/kafka_intake/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the KafkaIntake project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/kafka_intake/blob/master/CODE_OF_CONDUCT.md).
