# coding: utf-8, frozen_string_literal: true

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

        StatsD.gauge("#{@stats_metric_prefix}puma.backlog", stats.backlog)
        StatsD.gauge("#{@stats_metric_prefix}puma.running", stats.running)
        StatsD.gauge("#{@stats_metric_prefix}puma.pool_capacity", stats.pool_capacity)
        StatsD.gauge("#{@stats_metric_prefix}puma.max_threads", stats.max_threads)
        StatsD.gauge("#{@stats_metric_prefix}puma.workers", stats.workers)

        if stats.clustered?
          StatsD.gauge("#{@stats_metric_prefix}puma.booted_workers", stats.booted_workers)
          StatsD.gauge("#{@stats_metric_prefix}puma.old_workers", stats.old_workers)
        end
      rescue StandardError => e
        @launcher.events.error("! statsd: notify stats failed:\n  #{e.to_s}\n  #{e.backtrace.join("\n    ")}")
      ensure
        sleep @stats_polling_interval
      end
    end
  end
end
