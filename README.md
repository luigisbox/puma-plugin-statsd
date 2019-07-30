# Puma Statsd Plugin

[Puma][puma] integration with [statsd](statsd) for easy tracking of key metrics
that puma can provide:

* puma.backlog
* puma.running
* puma.pool_capacity
* puma.max_threads
* puma.workers
* puma.booted_workers (for puma instances running in clustered mode)
* puma.old_workers (for puma instances running in clustered mode)

  [puma]: https://github.com/puma/puma
  [statsd]: https://github.com/etsy/statsd

## Installation

Add this gem to your Gemfile with puma and then bundle:

```ruby
gem "puma"
gem "puma-plugin-statsd"
```

Add it to your puma config:

```ruby
# config/puma.rb

bind "http://127.0.0.1:9292"

workers 1
threads 8, 16

plugin :statsd
```

## Usage

Ensure you have an `STATSD_ADDR` environment variable set that points to a statsd host, then boot your puma app as usual.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/luigisbox/puma-plugin-statsd.

## Testing the data being sent to statsd

Start a pretend statsd server that listens for UDP packets on port 8125:

    ruby devtools/statsd-to-stdout.rb

Start puma:

    STATSD_HOST=127.0.0.1 bundle exec puma devtools/config.ru --config devtools/puma-config.rb

Throw some traffic at it, either with curl or a tool like ab:

    curl http://127.0.0.1:9292/
    ab -n 10000 -c 20 http://127.0.0.1:9292/

Watch the output of the UDP server process - you should see statsd data printed to stdout.

## Acknowledgements

This gem is a fork of [puma-plugin-statsd](puma-plugin-statsd), which itself is a fork of the excellent [puma-plugin-systemd][puma-plugin-systemd] by
Samuel Cochran.

  [puma-plugin-systemd]: https://github.com/sj26/puma-plugin-systemd

Other puma plugins that were helpful references:

* [yabeda-puma-plugin](https://github.com/yabeda-rb/yabeda-puma-plugin)
* [puma-heroku](https://github.com/evanphx/puma-heroku)
* [tmp-restart](https://github.com/puma/puma/blob/master/lib/puma/plugin/tmp_restart.rb)

The [puma docs](https://github.com/puma/puma/blob/master/docs/plugins.md) were also helpful.

## License

The gem is available as open source under the terms of the [MIT License][license].

  [license]: http://opensource.org/licenses/MIT
