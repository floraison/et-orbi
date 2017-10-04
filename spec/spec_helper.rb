
#
# Specifying et-orbi
#
# Sat Mar 18 16:17:38 JST 2017
#

require 'pp'
#require 'ostruct'

require 'et-orbi'


puts '-' * 80
  #
puts `uname -a`
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
  else
    ENV['TZ'] = zone_name || EtOrbi.os_tz
  end

#p [ :in_zone, :etz, ENV['TZ'] ]
#p [ :in_zone, :now, Time.now, Time.now.zone ]
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
end

