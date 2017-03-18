
#
# Specifying et-orbi
#
# Sat Mar 18 16:17:38 JST 2017
#

require 'pp'
#require 'ostruct'

require 'et-orbi'


#def jruby?
#
#  !! RUBY_PLATFORM.match(/java/)
#end


def in_zone(zone_name, &block)

  prev_tz = ENV['TZ']
  ENV['TZ'] = zone_name

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

