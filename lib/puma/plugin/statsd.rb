# coding: utf-8, frozen_string_literal: true

require 'securerandom'
require 'puma'
require 'puma/plugin'
require 'statsd-instrument'
require 'oj'

class PumaStats
  def initialize(stats)
    @stats = stats
  end

  def clustered?
    @stats.has_key?('workers')
  end

  def workers
    @stats.fetch('workers', 1)
  end

  def booted_workers
    @stats.fetch('booted_workers', 1)
  end

  def old_workers
    @stats.fetch('old_workers', 0)
  end

  def running
    if clustered?
      @stats['worker_status'].map { |s| s['last_status'].fetch('running', 0) }.inject(0, &:+)
    else
      @stats.fetch('running', 0)
    end
  end

  def backlog
    if clustered?
      @stats['worker_status'].map { |s| s['last_status'].fetch('backlog', 0) }.inject(0, &:+)
    else
      @stats.fetch('backlog', 0)
    end
  end

  def pool_capacity
    if clustered?
      @stats['worker_status'].map { |s| s['last_status'].fetch('pool_capacity', 0) }.inject(0, &:+)
    else
      @stats.fetch('pool_capacity', 0)
    end
  end

  def max_threads
    if clustered?
      @stats['worker_status'].map { |s| s['last_status'].fetch('max_threads', 0) }.inject(0, &:+)
    else
      @stats.fetch('max_threads', 0)
    end
  end
end

Puma::Plugin.create do
  def initialize(loader)
    @loader = loader
    @instance_uuid = SecureRandom.uuid
    @stats_metric_prefix = ENV.fetch('PUMA_STATS_METRIC_PREFIX') { '' }
    @stats_polling_interval = ENV.fetch('PUMA_STATS_POLLING_INTERVAL') { 5 }.to_i
  end

  def start(launcher)
    @launcher = launcher

    in_background(&method(:stats_loop))
  end

  private

  def fetch_stats
    Oj.load(Puma.stats)
  end

  def stats_loop
    sleep @stats_polling_interval
    loop do
      @launcher.events.debug "statsd: notify statsd"
      begin
        stats = ::PumaStats.new(fetch_stats)

        report('backlog', stats.backlog)
        report('running', stats.running)
        report('pool_capacity', stats.pool_capacity)
        report('max_threads', stats.max_threads)
        report('workers', stats.workers)

        if stats.clustered?
          report('booted_workers', stats.booted_workers)
          report('old_workers', stats.old_workers)
        end
      rescue StandardError => e
        @launcher.events.error("! statsd: notify stats failed:\n  #{e.to_s}\n  #{e.backtrace.join("\n    ")}")
      ensure
        sleep @stats_polling_interval
      end
    end
  end

  def report(key, value)
    StatsD.gauge("#{@stats_metric_prefix}puma.#{@instance_uuid}.#{key}", value)
  end
end
