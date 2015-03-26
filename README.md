# Realtime Metrics Vagrant VM

## Introduction

This is a simple VM for quickly spinning up a collector and dashboard display for realtime stats. It's the equivalent of our Docker container, except it uses a traditional VM for improved stability and performance.

The version of Graphite included in this VM has been modified to capture and display data at 1 second resolution. Stock Graphite only supports 1 minute resolution or higher. This is very handy for measuring tests using [Storyplayer](https://datasift.github.io/storyplayer/) and [SavageD](https://github.com/ganbarodigital/SavageD).

See [Stuart's blog post on realtime graphing with Graphite](http://blog.stuartherbert.com/php/2011/09/21/real-time-graphing-with-graphite/) for more details.

This VM is based on [Kamon's container](https://github.com/kamon-io/docker-grafana-graphite). Check our their container if you want Graphite but don't need realtime stats!

## Includes

* Grafana for nice-looking dashboards on port 80
* Graphite's webapp on port 81
* statsd collector on port 8125/udp

## License

See [LICENSE.md](LICENSE.md) for details.