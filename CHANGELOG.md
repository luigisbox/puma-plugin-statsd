# CHANGELOG

## 0.2.1 2019-07-31

* Metrics are sent including unique key for puma instance to allow monitoring multiple service instances at the same time

## 0.2.0 2019-07-30

* Statsd integration is now via `statsd-instrument` dependency
* Statsd metrics can be prefixed with environment variables
* Puma stats polling interval is now configurable
* Removed DataDog integration

## 0.1.0 2019-07-06

* The statsd port is now configurable
* Support puma 4.x

## 0.0.1 2018-07-17

Initial Release
