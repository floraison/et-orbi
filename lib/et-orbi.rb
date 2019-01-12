
require 'date' if RUBY_VERSION < '1.9.0'
require 'time'

require 'tzinfo'

require 'et-orbi/eo_time'
require 'et-orbi/zone_aliases'


module EtOrbi

  VERSION = '1.1.7'

  #
  # module methods

  class << self

    def now(zone=nil)

      EoTime.new(Time.now.to_f, zone)
    end

    def parse(str, opts={})

      str, str_zone = extract_zone(str)

      if defined?(::Chronic) && t = ::Chronic.parse(str, opts)

        str = [ t.strftime('%F %T'), str_zone ].compact.join(' ')
      end

      begin
        DateTime.parse(str)
      rescue
        fail ArgumentError, "No time information in #{str.inspect}"
      end
      #end if RUBY_VERSION < '1.9.0'
      #end if RUBY_VERSION < '2.0.0'
        #
        # is necessary since Time.parse('xxx') in Ruby < 1.9 yields `now`

      zone =
        opts[:zone] ||
        get_tzone(str_zone) ||
        determine_local_tzone

      local = Time.parse(str)
      secs = zone.local_to_utc(local).to_f

      EoTime.new(secs, zone)
    end

    def make_time(*a)

      zone = a.length > 1 ? get_tzone(a.last) : nil
      a.pop if zone

      o = a.length > 1 ? a : a.first

      case o
      when Time then make_from_time(o, zone)
      when Date then make_from_date(o, zone)
      when Array then make_from_array(o, zone)
      when String then make_from_string(o, zone)
      when Numeric then make_from_numeric(o, zone)
      when ::EtOrbi::EoTime then make_from_eotime(o, zone)
      else fail ArgumentError.new(
        "Cannot turn #{o.inspect} to a ::EtOrbi::EoTime instance")
      end
    end
    alias make make_time

    def make_from_time(t, zone)

      z =
        zone ||
        get_as_tzone(t) ||
        get_tzone(t.zone) ||
        get_local_tzone(t)

      z ||= t.zone
        # pass the abbreviation anyway,
        # it will be used in the resulting error message

      EoTime.new(t, z)
    end

    def make_from_date(d, zone)

      make_from_time(
        d.respond_to?(:to_time) ?
        d.to_time :
        Time.parse(d.strftime('%Y-%m-%d %H:%M:%S')),
        zone)
    end

    def make_from_array(a, zone)

      t = Time.utc(*a)
      s = t.strftime("%Y-%m-%d %H:%M:%S.#{'%06d' % t.usec}")

      make_from_string(s, zone)
    end

    def make_from_string(s, zone)

      parse(s, zone: zone)
    end

    def make_from_numeric(f, zone)

      EoTime.new(Time.now.to_f + f, zone)
    end

    def make_from_eotime(eot, zone)

      return eot if zone == nil || zone == eot.zone
      EoTime.new(eot.to_f, zone)
    end

    def get_tzone(o)

      return o if o.is_a?(::TZInfo::Timezone)
      return nil if o == nil
      return determine_local_tzone if o == :local
      return ::TZInfo::Timezone.get('Zulu') if o == 'Z'
      return o.tzinfo if o.respond_to?(:tzinfo)

      o = to_offset(o) if o.is_a?(Numeric)

      return nil unless o.is_a?(String)

      s = unalias(o)

      get_offset_tzone(s) ||
      get_x_offset_tzone(s) ||
      (::TZInfo::Timezone.get(s) rescue nil)
    end

    def render_nozone_time(seconds)

      t =
        Time.utc(1970) + seconds
      ts =
        t.strftime('%Y-%m-%d %H:%M:%S') +
        ".#{(seconds % 1).to_s.split('.').last}"
      tz =
        EtOrbi.determine_local_tzone
      z =
        tz ? tz.period_for_local(t).abbreviation.to_s : nil

      "(secs:#{seconds},utc~:#{ts.inspect},ltz~:#{z.inspect})"
    end

    def tzinfo_version

      #TZInfo::VERSION
      Gem.loaded_specs['tzinfo'].version.to_s
    rescue => err
      err.inspect
    end

    def tzinfo_data_version

      #TZInfo::Data::VERSION rescue nil
      Gem.loaded_specs['tzinfo-data'].version.to_s rescue nil
    end

    def platform_info

      etos = Proc.new { |k, v| "#{k}:#{v.inspect}" }

      h = {
        'etz' => ENV['TZ'],
        'tnz' => Time.now.zone,
        'tziv' => tzinfo_version,
        'tzidv' => tzinfo_data_version,
        'rv' => RUBY_VERSION,
        'rp' => RUBY_PLATFORM,
        'win' => Gem.win_platform?,
        'rorv' => (Rails::VERSION::STRING rescue nil),
        'astz' => ([ Time.zone.class, Time.zone.tzinfo.name ] rescue nil),
        'eov' => EtOrbi::VERSION,
        'eotnz' => '???',
        'eotnfz' => '???',
        'eotlzn' => '???' }
      if ltz = EtOrbi::EoTime.local_tzone
        h['eotnz'] = EtOrbi::EoTime.now.zone
        h['eotnfz'] = EtOrbi::EoTime.now.strftime('%z')
        h['eotnfZ'] = EtOrbi::EoTime.now.strftime('%Z')
        h['eotlzn'] = ltz.name
      end

      "(#{h.map(&etos).join(',')},#{gather_tzs.map(&etos).join(',')})"
    end

    # For `make info`
    #
    def _make_info

      puts render_nozone_time(Time.now.to_f)
      puts platform_info
    end

    ZONES_ISO8601 =
      %r{
        (?<=:\d\d)\s*
        (?:
          [-+]
          (?:[0-1][0-9]|2[0-4])
          (?:(?::)?(?:[0-5][0-9]|60))?
          (?![-+])
            |Z
        )
      }x

    # https://en.wikipedia.org/wiki/ISO_8601
    # Postel's law applies
    #
    def list_iso8601_zones(s)

      s.scan(ZONES_ISO8601).collect(&:strip)
    end

    ZONES_OLSON = (
      TZInfo::Timezone.all.collect { |z| z.name }.sort +
      (0..12).collect { |i| [ "UTC-#{i}", "UTC+#{i}" ] })
        .flatten
        .sort_by(&:size)
        .reverse

    def list_olson_zones(s)

      s = s.dup

      ZONES_OLSON
        .inject([]) { |a, z|
          i = s.index(z); next a unless i
          s[i, z.length] = ''
          a << z
          a }
    end

    def find_olson_zone(str)

      list_olson_zones(str).each { |s| z = get_tzone(s); return z if z }
      nil
    end

    def extract_zone(str)

      s = str.dup

      zs = ZONES_OLSON
        .inject([]) { |a, z|
          i = s.index(z); next a unless i
          a << z
          s[i, z.length] = ''
          a }

      s.gsub!(ZONES_ISO8601) { |m| zs << m.strip; '' } #if zs.empty?

      zs = zs.sort_by { |z| str.index(z) }

      [ s.strip, zs.last ]
    end

    def determine_local_tzone

      # ENV has the priority

      etz = ENV['TZ']

      tz = etz && get_tzone(etz)
      return tz if tz

      # then Rails/ActiveSupport has the priority

      if Time.respond_to?(:zone) && Time.zone.respond_to?(:tzinfo)
        tz = Time.zone.tzinfo
        return tz if tz
      end

      # then the operating system is queried

      tz = ::TZInfo::Timezone.get(os_tz) rescue nil
      return tz if tz

      # then Ruby's time zone abbs are looked at CST, JST, CEST, ... :-(

      tzs = determine_local_tzones
      tz = (etz && tzs.find { |z| z.name == etz }) || tzs.first
      return tz if tz

      # then, fall back to GMT offest :-(

      n = Time.now

      get_tzone(n.zone) ||
      get_tzone(n.strftime('%Z%z'))
    end
    alias zone determine_local_tzone

    attr_accessor :_os_zone # test tool

    def os_tz

      return (@_os_zone == '' ? nil : @_os_zone) \
        if defined?(@_os_zone) && @_os_zone

      @os_tz ||= (debian_tz || centos_tz || osx_tz)
    end

    # Semi-helpful, since it requires the current time
    #
    def windows_zone_name(zone_name, time)

      twin = Time.utc(time.year, 1, 1) # winter
      tsum = Time.utc(time.year, 7, 1) # summer

      tz = ::TZInfo::Timezone.get(zone_name)
      tzo = tz.period_for_local(time).utc_total_offset
      tzop = tzo < 0 ? nil : '-'; tzo = tzo.abs
      tzoh = tzo / 3600
      tzos = tzo % 3600
      tzos = tzos == 0 ? nil : ':%02d' % (tzos / 60)

      abbs = [
        tz.period_for_utc(twin).abbreviation.to_s,
        tz.period_for_utc(tsum).abbreviation.to_s ]
          .uniq

      if abbs[0].match(/\A[A-Z]/)
        [ abbs[0], tzop, tzoh, tzos, abbs[1] ]
          .compact.join
      else
        [ windows_zone_code_x(zone_name), tzop, tzoh, tzos || ':00', zone_name ]
          .collect(&:to_s).join
      end
    end

    #
    # protected module methods

    protected

    def windows_zone_code_x(zone_name)

      a = [ '_' ]
      a.concat(zone_name.split('/')[0, 2].collect { |s| s[0, 1].upcase })
      a << '_' if a.size < 3

      a.join
    end

    def get_local_tzone(t)

      l = Time.local(t.year, t.month, t.day, t.hour, t.min, t.sec, t.usec)

      (t.zone == l.zone) ? determine_local_tzone : nil
    end

    # https://api.rubyonrails.org/classes/ActiveSupport/TimeWithZone.html
    #
    # If it responds to #time_zone, then return that time zone.
    #
    def get_as_tzone(t)

      t.respond_to?(:time_zone) ? t.time_zone : nil
    end

    def to_offset(n)

      i = n.to_i
      sn = i < 0 ? '-' : '+'; i = i.abs
      hr = i / 3600; mn = i % 3600; sc = i % 60

      sc > 0 ?
        '%s%02d:%02d:%02d' % [ sn, hr, mn, sc ] :
        '%s%02d:%02d' % [ sn, hr, mn ]
    end

    # custom timezones, no DST, just an offset, like "+08:00" or "-01:30"
    #
    def get_offset_tzone(str)

      m = str.match(/\A([+-][0-1]?[0-9]):?([0-5][0-9])?\z/) rescue nil
        #
        # On Windows, the real encoding could be something other than UTF-8,
        # and make the match fail
        #
      return nil unless m

      tz = custom_tzs[str]
      return tz if tz

      hr = m[1].to_i
      mn = m[2].to_i

      hr = nil if hr.abs > 11
      hr = nil if mn > 59
      mn = -mn if hr && hr < 0

      hr ?
        custom_tzs[str] = create_offset_tzone(hr * 3600 + mn * 60, str) :
        nil
    end

    if defined?(TZInfo::DataSources::ConstantOffsetDataTimezoneInfo)
      # TZInfo >= 2.0.0

      def create_offset_tzone(utc_off, id)

        off = TZInfo::TimezoneOffset.new(utc_off, 0, id)
        tzi = TZInfo::DataSources::ConstantOffsetDataTimezoneInfo.new(id, off)
        tzi.create_timezone
      end

    else
      # TZInfo < 2.0.0

      def create_offset_tzone(utc_off, id)

        tzi = TZInfo::TransitionDataTimezoneInfo.new(id)
        tzi.offset(id, utc_off, 0, id)
        tzi.create_timezone
      end
    end

    def get_x_offset_tzone(str)

      m = str.match(/\A_..-?[0-1]?\d:?(?:[0-5]\d)?(.+)\z/) rescue nil
        #
        # On Windows, the real encoding could be something other than UTF-8,
        # and make the match fail (as in .get_offset_tzone above)

      m ? ::TZInfo::Timezone.get(m[1]) : nil
    end

    def determine_local_tzones

      tabbs = (-6..5)
        .collect { |i|
          t = Time.now + i * 30 * 24 * 3600
          "#{t.zone}_#{t.utc_offset}" }
        .uniq
        .sort
        .join('|')

      t = Time.now
      #tu = t.dup.utc # /!\ dup is necessary, #utc modifies its target

      twin = Time.local(t.year, 1, 1) # winter
      tsum = Time.local(t.year, 7, 1) # summer

      @tz_winter_summer ||= {}

      @tz_winter_summer[tabbs] ||= tz_all
        .select { |tz|
          pw = tz.period_for_local(twin)
          ps = tz.period_for_local(tsum)
          tabbs ==
            [ "#{pw.abbreviation}_#{pw.utc_total_offset}",
              "#{ps.abbreviation}_#{ps.utc_total_offset}" ]
              .uniq.sort.join('|') }

      @tz_winter_summer[tabbs]
    end

    def custom_tzs; @custom_tzs ||= {}; end
    def tz_all; @tz_all ||= ::TZInfo::Timezone.all; end

    #
    # system tz determination

    def debian_tz

      path = '/etc/timezone'

      File.exist?(path) ? File.read(path).strip : nil
    rescue; nil; end

    def centos_tz

      path = '/etc/sysconfig/clock'

      File.open(path, 'rb') do |f|
        until f.eof?
          if m = f.readline.match(/ZONE="([^"]+)"/); return m[1]; end
        end
      end if File.exist?(path)

      nil
    rescue; nil; end

    def osx_tz

      path = '/etc/localtime'

      File.symlink?(path) ?
        File.readlink(path).split('/')[4..-1].join('/') :
        nil
    rescue; nil; end

    def gather_tzs

      { :debian => debian_tz, :centos => centos_tz, :osx => osx_tz }
    end
  end
end

