
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

