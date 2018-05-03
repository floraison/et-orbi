
require 'et-orbi'
require 'active_support'
require "active_support/core_ext"
require "active_support/time_with_zone"

#p ActiveSupport::TimeWithZone
#p ActiveSupport::TimeWithZone.ancestors
#
#p Time.now + 1.minute
#p (Time.now + 1.minute).class
#p EtOrbi.get_tzone('Asia/Tokyo')
#p ActiveSupport::TimeWithZone.new(Time.now, EtOrbi.get_tzone('Asia/Tokyo'))
#p ActiveSupport::TimeWithZone.new(Time.now, EtOrbi.get_tzone('Asia/Tokyo')).class

#      def parse_at(o, opts={})
#
#        return o if o.is_a?(EoTime)
#        return EoTime.make(o) if o.is_a?(Time)
#        EoTime.parse(o, opts)
#
#      rescue StandardError => se
#
#        return nil if opts[:no_error]
#        fail se
#      end

# ArgumentError
#   (couldn't parse Wed, 04 Oct 2017 23:47:00 EDT -04:00
#       (ActiveSupport::TimeWithZone)):

ENV['TZ'] = 'America/New_York'
#ENV['TZ'] = 'UTC'
t = ActiveSupport::TimeWithZone.new(Time.now, EtOrbi.get_tzone('America/New_York'))
p t.to_s
p t.inspect
p t
p t.is_a?(Time)
#p t + 1.minute
#p (t + 1.minute).is
p EtOrbi.make(t.inspect)
#p EtOrbi.parse(t, {})

