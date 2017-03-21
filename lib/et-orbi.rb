
require 'tzinfo'


module EtOrbi

  VERSION = '1.0.0'

  class EoTime

#    def self.debian_tz
#
#      path = '/etc/timezone'
#
#      File.exist?(path) ? File.read(path).strip : nil
#    rescue; nil; end
#
#    def self.centos_tz
#
#      path = '/etc/sysconfig/clock'
#
#      File.open(path, 'rb') do |f|
#        until f.eof?
#          if m = f.readline.match(/ZONE="([^"]+)"/); return m[1]; end
#        end
#      end if File.exist?(path)
#
#      nil
#    rescue; nil; end
#
#    def self.osx_tz
#
#      path = '/etc/localtime'
#
#      File.symlink?(path) ?
#        File.readlink(path).split('/')[4..-1].join('/') :
#        nil
#    rescue; nil; end
#
#    def self.find_tz
#
#      debian_tz || centos_tz || osx_tz
#    end
#
#    def self.gather_tzs
#
#      { :debian => debian_tz, :centos => centos_tz, :osx => osx_tz }
#    end

    #
    # class methods

    def self.now(zone=nil)

      EoTime.new(Time.now.to_f, zone)
    end

    def self.parse(str, opts={})

      if defined?(::Chronic) && t = ::Chronic.parse(str, opts)
        return EoTime.new(t, nil)
      end

      #rold = RUBY_VERSION < '1.9.0'
      #rold = RUBY_VERSION < '2.0.0'

      begin
        DateTime.parse(str)
      rescue
        fail ArgumentError, "no time information in #{str.inspect}"
      end #if rold
        #
        # is necessary since Time.parse('xxx') in Ruby < 1.9 yields `now`

#p str
      local = Time.parse(str)

      izone = get_tzone(list_iso8601_zones(str).last)

      zone = izone
      list_olson_zones(str).each { |s| break if zone; zone = get_tzone(s) }

      zone ||= get_tzone(:local)

      secs =
        if izone
          local.to_f
        else
          zone.period_for_local(local).to_utc(local).to_f
        end

      EoTime.new(secs, zone)
    end

    def self.make(o)

      ot =
        case o
          when Time
            EoTime.new(o.to_f, o.zone)
          when Date
            t =
              o.respond_to?(:to_time) ?
              o.to_time :
              Time.parse(o.strftime('%Y-%m-%d %H:%M:%S'))
            EoTime.new(t.to_f, t.zone)
          when String
            #Rufus::Scheduler.parse_in(o, :no_error => true) || self.parse(o)
            self.parse(o)
          else
            o
        end

      ot = EoTime.new(Time.now.to_f + ot, nil) if ot.is_a?(Numeric)

      fail ArgumentError.new(
        "cannot turn #{o.inspect} to a EoTime instance"
      ) unless ot.is_a?(EoTime)

      ot
    end

    def self.to_offset(n)

      i = n.to_i
      sn = i < 0 ? '-' : '+'; i = i.abs
      hr = i / 3600; mn = i % 3600; sc = i % 60
      (sc > 0 ? "%s%02d:%02d:%02d" : "%s%02d:%02d") % [ sn, hr, mn, sc ]
    end

    def self.get_tzone(o)

#p [ :gtz, o ]
      return nil if o == nil
      return local_tzone if o == :local
      return o if o.is_a?(::TZInfo::Timezone)
      return ::TZInfo::Timezone.get('Zulu') if o == 'Z'

      o = to_offset(o) if o.is_a?(Numeric)

      return nil unless o.is_a?(String)

      (@custom_tz_cache ||= {})[o] ||
      get_offset_tzone(o) ||
      (::TZInfo::Timezone.get(o) rescue nil)
    end

    def self.get_offset_tzone(str)

      # custom timezones, no DST, just an offset, like "+08:00" or "-01:30"

      m = str.match(/\A([+-][0-1][0-9]):?([0-5][0-9])?\z/)
      return nil unless m

      hr = m[1].to_i
      mn = m[2].to_i

      hr = nil if hr.abs > 11
      hr = nil if mn > 59
      mn = -mn if hr && hr < 0

      return (
        @custom_tz_cache[str] =
          begin
            tzi = TZInfo::TransitionDataTimezoneInfo.new(str)
            tzi.offset(str, hr * 3600 + mn * 60, 0, str)
            tzi.create_timezone
          end
      ) if hr

      nil
    end

    def self.local_tzone

      @local_tzone = nil \
        if @local_tzone_loaded_at && (Time.now > @local_tzone_loaded_at + 1800)
      @local_tzone = nil \
        if @local_tzone_tz != ENV['TZ']

      @local_tzone ||=
        begin
          @local_tzone_tz = ENV['TZ']
          @local_tzone_loaded_at = Time.now
          determine_local_tzone
        end
    end

    def self.determine_local_tzone

      etz = ENV['TZ']

      tz = ::TZInfo::Timezone.get(etz) rescue nil
      return tz if tz

      tz = Time.zone.tzinfo \
        if Time.respond_to?(:zone) && Time.zone.respond_to?(:tzinfo)
      return tz if tz

      tzs = determine_local_tzones

      (etz && tzs.find { |z| z.name == etz }) || tzs.first
    end

    def self.determine_local_tzones

      tabbs = (-6..5)
        .collect { |i| (Time.now + i * 30 * 24 * 3600).zone }
        .uniq
        .sort

      t = Time.now
      tu = t.dup.utc # /!\ dup is necessary, #utc modifies its target

      twin = Time.utc(t.year, 1, 1) # winter
      tsum = Time.utc(t.year, 7, 1) # summer

      ::TZInfo::Timezone.all.select do |tz|

        pabbs =
          [
            tz.period_for_utc(twin).abbreviation.to_s,
            tz.period_for_utc(tsum).abbreviation.to_s
          ].uniq.sort

        pabbs == tabbs
      end
    end

    # https://en.wikipedia.org/wiki/ISO_8601
    # Postel's law applies
    #
    def self.list_iso8601_zones(s)

      s.scan(
        %r{
          (?<=:\d\d)
          \s*
          (?:
            [-+]
            (?:[0-1][0-9]|2[0-4])
            (?:(?::)?(?:[0-5][0-9]|60))?
            (?![-+])
            |
            Z
          )
        }x
        ).collect(&:strip)
    end

    def self.list_olson_zones(s)

      s.scan(
        %r{
          (?<=\s|\A)
          (?:[A-Za-z][A-Za-z0-9+_-]+)
          (?:\/(?:[A-Za-z][A-Za-z0-9+_-]+)){0,2}
        }x)
    end

    #def in_zone(&block)
    #
    #  current_timezone = ENV['TZ']
    #  ENV['TZ'] = @zone
    #
    #  block.call
    #
    #ensure
    #
    #  ENV['TZ'] = current_timezone
    #end
      #
      # kept around as a (thread-unsafe) relic

    #
    # instance methods

    attr_reader :seconds
    attr_reader :zone

    def initialize(s, zone)

      @seconds = s.to_f
      @zone = self.class.get_tzone(zone || :local)

      #fail ArgumentError.new(
      #  "cannot determine timezone from #{zone.inspect}" +
      #  " (etz:#{ENV['TZ'].inspect},tnz:#{Time.now.zone.inspect}," +
      #  "tzid:#{defined?(TZInfo::Data).inspect}," +
      #  "rv:#{RUBY_VERSION.inspect},rp:#{RUBY_PLATFORM.inspect}," +
      #  "stz:(#{self.class.gather_tzs.map { |k, v| "#{k}:#{v.inspect}"}.join(',')})) \n" +
      #  "Try setting `ENV['TZ'] = 'Continent/City'` in your script " +
      #  "(see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)" +
      #  (defined?(TZInfo::Data) ? '' : " and adding 'tzinfo-data' to your gems")
      #) unless @zone
fail unless @zone

      @time = nil # cache for #to_time result
    end

    def seconds=(f)

      @time = nil
      @seconds = f
    end

    def zone=(z)

      @time = nil
      @zone = self.class.get_tzone(zone || :current)
    end

    def utc

      Time.utc(1970, 1, 1) + @seconds
    end

    alias getutc utc
    alias getgm utc

    def to_f

      @seconds
    end

    def to_i

      @seconds.to_i
    end

    def strftime(format)

      format = format.gsub(/%(\/?Z|:{0,2}z)/) { |f| strfz(f) }

      to_time.strftime(format)
    end

    # Returns a Ruby Time instance.
    #
    # Warning: the timezone of that Time instance will be UTC.
    #
    def to_time

      @time ||= begin; u = utc; @zone.period_for_utc(u).to_local(u); end
    end

    def is_dst?

      @zone.period_for_utc(utc).std_offset != 0
    end
    alias isdst is_dst?

    def to_debug_s

      uo = self.utc_offset
      uos = uo < 0 ? '-' : '+'
      uo = uo.abs
      uoh, uom = [ uo / 3600, uo % 3600 ]

      [
        'ot',
        self.strftime('%Y-%m-%d %H:%M:%S'),
        "%s%02d:%02d" % [ uos, uoh, uom ],
        "dst:#{self.isdst}"
      ].join(' ')
    end

    def utc_offset

      #@zone.period_for_utc(utc).utc_offset
      #@zone.period_for_utc(utc).utc_total_offset
      #@zone.period_for_utc(utc).std_offset
      @zone.period_for_utc(utc).utc_offset
    end

    %w[
      year month day wday hour min sec usec asctime
    ].each do |m|
      define_method(m) { to_time.send(m) }
    end
    def iso8601(fraction_digits=0); to_time.iso8601(fraction_digits); end

    def ==(o)

      o.is_a?(EoTime) && o.seconds == @seconds && o.zone == @zone
    end
    #alias eq? == # FIXME see Object#== (ri)

    def >(o); @seconds > _to_f(o); end
    def >=(o); @seconds >= _to_f(o); end
    def <(o); @seconds < _to_f(o); end
    def <=(o); @seconds <= _to_f(o); end
    def <=>(o); @seconds <=> _to_f(o); end

    def add(t); @time = nil; @seconds += t.to_f; end
    def subtract(t); @time = nil; @seconds -= t.to_f; end

    def +(t); inc(t, 1); end
    def -(t); inc(t, -1); end

    WEEK_S = 7 * 24 * 3600

    def monthdays

      date = to_time

      pos = 1
      d = self.dup

      loop do
        d.add(-WEEK_S)
        break if d.month != date.month
        pos = pos + 1
      end

      neg = -1
      d = self.dup

      loop do
        d.add(WEEK_S)
        break if d.month != date.month
        neg = neg - 1
      end

      [ "#{date.wday}##{pos}", "#{date.wday}##{neg}" ]
    end

    def to_s

      strftime('%Y-%m-%d %H:%M:%S %z')
    end

    # Debug current time by showing local time / delta / utc time
    # for example: "0120-7(0820)"
    #
    def to_utc_comparison_s

      per = @zone.period_for_utc(utc)
      off = per.utc_total_offset

      off = off / 3600
      off = off >= 0 ? "+#{off}" : off.to_s

      strftime('%H%M') + off + utc.strftime('(%H%M)')
    end

    def to_time_s

      strftime("%H:%M:%S.#{'%06d' % usec}")
    end

    #
    # protected

    def strfz(code)

      return @zone.name if code == '%/Z'

      per = @zone.period_for_utc(utc)

      return per.abbreviation.to_s if code == '%Z'

      off = per.utc_total_offset
        #
      sn = off < 0 ? '-' : '+'; off = off.abs
      hr = off / 3600
      mn = (off % 3600) / 60
      sc = 0

      fmt =
        if code == '%z'
          "%s%02d%02d"
        elsif code == '%:z'
          "%s%02d:%02d"
        else
          "%s%02d:%02d:%02d"
        end

      fmt % [ sn, hr, mn, sc ]
    end

    def inc(t, dir)

      if t.is_a?(Numeric)
        nt = self.dup
        nt.seconds += dir * t.to_f
        nt
      elsif t.respond_to?(:to_f)
        @seconds + dir * t.to_f
      else
        fail ArgumentError.new(
          "cannot call EoTime #- or #+ with arg of class #{t.class}")
      end
    end

    def _to_f(o)

      fail ArgumentError(
        "comparison of EoTime with #{o.inspect} failed"
      ) unless o.is_a?(EoTime) || o.is_a?(Time)

      o.to_f
    end
  end
end

