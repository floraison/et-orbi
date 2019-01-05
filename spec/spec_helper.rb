
#
# Specifying et-orbi
#
# Sat Mar 18 16:17:38 JST 2017
#

ENV['_TZ'] = ENV['TZ'] # preserve original TZ if any

require 'pp'
#require 'ostruct'

require 'et-orbi'


puts '-' * 80
  #
puts `uname -a` rescue "(`uname -a` failed)"
puts [ RUBY_VERSION, RUBY_PLATFORM ].join(' ')
EtOrbi._make_info
  #
puts '-' * 80


#def jruby?
#
#  !! RUBY_PLATFORM.match(/java/)
#end


def in_zone(zone_name, &block)

  EtOrbi.class_eval do
    @local_tzone = nil
    @local_tzone_tz = nil
    @local_tzone_loaded_at = nil
  end

  prev_tz = ENV['TZ']

  if zone_name == :no_env_tz
    ENV.delete('TZ')
  elsif zone_name == nil
    ENV['TZ'] = EtOrbi.os_tz
  else
    zone_name = EtOrbi.to_windows_tz(zone_name) if Gem.win_platform?
    ENV['TZ'] = zone_name
  end

  block.call

ensure

  ENV['TZ'] = prev_tz
end

def local(*args)

  Time.local(*args)
end
alias lo local

def ltz(tz, *args)

  in_zone(tz) { Time.local(*args) }
end

class Time

  def to_debug_s

    uo = self.utc_offset
    uos = uo < 0 ? '-' : '+'
    uo = uo.abs
    uoh, uom = [ uo / 3600, uo % 3600 ]

    [
      't',
      self.strftime('%Y-%m-%d %H:%M:%S'),
      "%s%02d:%02d" % [ uos, uoh, uom ],
      "dst:#{self.isdst}"
    ].join(' ')
  end

  #
  # tools to "inject" a zone string at will

  alias _original_zone zone

  def zone

    self.class._zone || _original_zone
  end

  class << self

    attr_accessor :_zone # instance zone (Vanilla Ruby)

    def active_support_zone=(zone_or_zone_name)

      ENV['TZ'] = nil # so that the active_support zone has the priority

      z = zone_or_zone_name
      z = ::TZInfo::Timezone.get(z) if z.is_a?(String)

      if z
        @_as_zone = SpecActiveSupportTimeZone.new(z)
        def zone; @_as_zone; end
      else
        undef zone rescue nil
      end
    end
  end
end

class SpecActiveSupportTimeZone

  def initialize(z); @z = z; end
  def tzinfo; @z; end

  def self.make(s); self.new(::TZInfo::Timezone.get(s)); end
end

