#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]

## 0.3.0 - 2016-08-08
### Added
- `README.md` Details on setup and configuration
- `sensu-client` Standalone checks (metrics-sa_os.json)
- `influxdb`

### Changed
- `docker-compose` Expose all the RabbitMQ Management ports: 15672, 15673, 15674
- `extension-influxdb-metrics.rb` Upgrade to the last version
- `sensu-*/run.sh` Stop container if processes are not running

## 0.2.0 - 2016-08-05
### Added
- `docker-compose` Network separation

### Changed
- `rmq` Switch to using the rabbitmq_clusterer plugin cluster method

### Fixed
- Better detect HEALTHCHECK failures

## 0.1.0 - 2016-08-05
### Added
- Initial release

