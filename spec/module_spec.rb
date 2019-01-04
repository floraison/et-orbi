# encoding: UTF-8

#
# Specifying EtOrbi
#
# Wed Mar 11 21:17:36 JST 2015, quatre ans... (rufus-scheduler)
# Sun Mar 19 05:16:28 JST 2017
# Fri Mar 24 04:55:25 JST 2017 圓さんの家
#

#require 'chronic'
#Chro = ::Chronic

require 'spec_helper'


describe EtOrbi do

  after :each do

    Time._zone = nil
    Time._as_zone = nil
    EtOrbi._os_zone = nil

    #Object.send(:remove_const, :Chronic) rescue nil
  end

  describe '.list_iso8601_zones' do

    [

      [ '2016-11-01 12:30:09-01', %w[ -01 ] ],
      [ '2016-11-01 12:30:09-01:00', %w[ -01:00 ] ],
      [ '2016-11-01 12:30:09 -01', %w[ -01 ] ],
      [ '2016-11-01 12:30:09 -01:00', %w[ -01:00 ] ],

      [ '2016-11-01 12:30:09-01:30', %w[ -01:30 ] ],
      [ '2016-11-01 12:30:09 -01:30', %w[ -01:30 ] ],

      [ '2016-11-01 12:30:09', [] ],
      [ '2016-11-01 12:30:09-25', [] ],
      [ '2016-11-01 12:30:09-25:00', [] ],

    ].each do |string, zones|

      it "returns #{zones.inspect} for #{string.inspect}" do

        expect(EtOrbi.list_iso8601_zones(string)).to eq(zones)
      end
    end
  end

  describe '.list_olson_zones' do

    [

      [ '11/09/2002 America/New_York',
        %w[ America/New_York ] ],
      [ '11/09/2002 America/New_York Asia/Shanghai',
        %w[ America/New_York Asia/Shanghai ] ],
      [ 'America/New_York Asia/Shanghai',
        %w[ America/New_York Asia/Shanghai ] ],
      [ '2018-09-04 07:54:58 Etc/GMT-11',
        %w[ Etc/GMT-11 ] ],

      [ '2018-09-04 07:54:58 UTC+11',
        %w[ UTC+11 ] ],
      [ '2018-09-04 07:54:58 UTC+11 Etc/GMT-11',
        %w[ UTC+11 Etc/GMT-11 ] ],
          #
          # https://github.com/floraison/fugit/issues/9

      [ '11/09/2002 2utopiaNada?3Nada',
        [] ]

    ].each do |string, zones|

      it "returns #{zones.inspect} for #{string.inspect}" do

        expect(EtOrbi.list_olson_zones(string)).to eq(zones)
      end
    end
  end

  describe '.parse' do

    it 'parses a time string without a timezone' do

      ot = in_zone('Europe/Moscow') { EtOrbi.parse('2015/03/08 01:59:59') }

      t = ot
      u = ot.utc

      expect(t.to_i).to eq(1425769199)
      expect(u.to_i).to eq(1425769199)

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{t.isdst}"
        ).to eq('2015/03/08 01:59:59 MSK +0300 false')

      expect(u.to_debug_s).to eq('t 2015-03-07 22:59:59 +00:00 dst:false')
    end

    it 'parses a time string with a full name timezone' do

      ot = EtOrbi.parse('2015/03/08 01:59:59 America/Los_Angeles')

      t = ot
      u = ot.utc

      expect(t.to_i).to eq(1425808799)
      expect(u.to_i).to eq(1425808799)

      expect(t.to_debug_s).to eq('ot 2015-03-08 01:59:59 -08:00 dst:false')
      expect(u.to_debug_s).to eq('t 2015-03-08 09:59:59 +00:00 dst:false')
    end

    it 'parses a time string with a delta timezone' do

      ot = in_zone('Europe/Berlin') { EtOrbi.parse('2015-12-13 12:30 -0200') }

      t = ot
      u = ot.utc

      expect(t.to_i).to eq(1450017000)
      expect(u.to_i).to eq(1450017000)

      expect(t.to_debug_s).to eq('ot 2015-12-13 12:30:00 -02:00 dst:false')
      expect(u.to_debug_s).to eq('t 2015-12-13 14:30:00 +00:00 dst:false')
    end

    it 'parses a time string with a delta (:) timezone' do

      ot = in_zone('Europe/Berlin') { EtOrbi.parse('2015-12-13 12:30 -02:00') }

      t = ot
      u = ot.utc

      expect(t.to_i).to eq(1450017000)
      expect(u.to_i).to eq(1450017000)

      expect(t.to_debug_s).to eq('ot 2015-12-13 12:30:00 -02:00 dst:false')
      expect(u.to_debug_s).to eq('t 2015-12-13 14:30:00 +00:00 dst:false')
    end

    it 'takes the local TZ when it does not know the timezone' do

      in_zone 'Europe/Moscow' do

        ot = EtOrbi.parse('2015/03/08 01:59:59 Nada/Nada')

        expect(ot.zone.name).to eq('Europe/Moscow')
      end
    end

    it 'parses even when the tz is out of place' do

      expect(
        EtOrbi.parse('Sun Nov 18 16:01:00 Asia/Singapore 2012')
          .to_debug_s
      ).to eq(
        "ot 2012-11-18 16:01:00 +08:00 dst:false"
      )
    end

    it 'fails on invalid strings' do

      expect {
        EtOrbi.parse('xxx')
      }.to raise_error(
        ArgumentError, 'No time information in "xxx"'
      )
    end

    it 'parses in the Rails-provided Time.zone (UTC)' do

      tz = ::TZInfo::Timezone.get('UTC')
      Time._as_zone = SpecActiveSupportTimeZone.new(tz)

      t = EtOrbi.parse('2019-01-01 12:10')

      expect(t.class).to eq(EtOrbi::EoTime)
      expect(t.zone).to eq(tz)
      expect(t.to_s).to eq('2019-01-01 12:10:00 Z')
      expect(t.to_zs).to eq('2019-01-01 12:10:00 UTC')
    end

    it 'parses in the Rails-provided Time.zone (Asia/Shanghai)' do

      tz = ::TZInfo::Timezone.get('Asia/Shanghai')
      Time._as_zone = SpecActiveSupportTimeZone.new(tz)

      t = EtOrbi.parse('2019-01-01 12:10')

      expect(t.class).to eq(EtOrbi::EoTime)
      expect(t.zone).to eq(tz)
      expect(t.to_s).to eq('2019-01-01 12:10:00 +0800')
      expect(t.to_zs).to eq('2019-01-01 12:10:00 Asia/Shanghai')
    end

#    it 'leverages Chronic if available' do
#
#      ::Chronic = ::Chro
#
#      n = Time.now + 24 * 3600
#      #z = EtOrbi.now.to_zs.split.last
#      z = EtOrbi.zone.name
#
#      t = EtOrbi.parse('tomorrow')
#
#      expect(t.class).to eq(EtOrbi::EoTime)
#      expect(t.to_zs).to eq("#{n.strftime('%Y-%m-%d')} 12:00:00 #{z}")
#    end
#
#    it 'leverages Chronic and Rails Time.zone (UTC) if available' do
#
#      ::Chronic = ::Chro
#
#      tz = ::TZInfo::Timezone.get('UTC')
#      Time._as_zone = SpecActiveSupportTimeZone.new(tz)
#
#      n = Time.now + 24 * 3600
#      t = EtOrbi.parse('tomorrow')
##p t.to_s
##p t.to_zs
#
#      expect(t.class).to eq(EtOrbi::EoTime)
#      expect(t.zone).to eq(tz)
#      expect(t.strftime('%Y-%m-%d')).to eq(n.strftime('%Y-%m-%d'))
#      expect(t.strftime('%H:%M:%S')).to eq('12:00:00')
#    end
#
#    it 'leverages Chronic and Rails Time.zone (Asia/Shanghai) if available' do
#
#      ::Chronic = ::Chro
#
#      tz = ::TZInfo::Timezone.get('Asia/Shanghai')
#      Time._as_zone = SpecActiveSupportTimeZone.new(tz)
#
#      n = Time.now + 24 * 3600
#      t = EtOrbi.parse('tomorrow')
##p t.to_s
##p t.to_zs
#
#      expect(t.class).to eq(EtOrbi::EoTime)
#      expect(t.zone).to eq(tz)
#      expect(t.strftime('%Y-%m-%d')).to eq(n.strftime('%Y-%m-%d'))
#      expect(t.strftime('%H:%M:%S')).to eq('12:00:00')
#    end
  end

  describe '.get_tzone' do

    {

      'GB' => 'GB',
      'UTC' => 'UTC',
      'GMT' => 'GMT',
      'Zulu' => 'Zulu',
      'Japan' => 'Japan',
      'Turkey' => 'Turkey',
      'Asia/Tokyo' => 'Asia/Tokyo',
      'Europe/Paris' => 'Europe/Paris',
      'Europe/Zurich' => 'Europe/Zurich',
      'W-SU' => 'W-SU',

      'Z' => 'Zulu',

      '+09:00' => '+09:00',
      '-01:30' => '-01:30',

      '+08:00' => '+08:00',
      '+0800' => '+0800', # no normalization to "+08:00"

      '-01' => '-01',

      3600 => '+01:00',

      'Tokyo Standard Time' => 'Asia/Tokyo',
      'Coordinated Universal Time' => 'UTC',

      'Eastern Standard Time' => 'America/New_York',
      'Eastern Daylight Time' => 'America/New_York',

      'CST+0800' => 'Asia/Chongqing',
      'CST+08:00' => 'Asia/Chongqing',
      'CST+08' => 'Asia/Chongqing',
      'CST+8' => 'Asia/Chongqing',
      'EDT-0400' => 'America/Detroit',

    }.each do |a, b|

      it "returns #{b.inspect} for #{a.inspect}" do

        z = EtOrbi.get_tzone(a)

        expect(z).not_to eq(nil)
        expect(z.name).to eq(b)
      end
    end

#    it 'returns a timezone for well-known abbreviations' do
#
#      expect(gtz('JST')).to eq('Japan')
#      expect(gtz('PST')).to eq('America/Dawson')
#      expect(gtz('CEST')).to eq('Africa/Ceuta')
#    end

    [
      'Asia/Paris', 'Nada/Nada', '7', '06', 'sun#3', 'Mazda Zoom Zoom Stadium'
    ].each do |s|

      it "returns nil for #{s.inspect}" do

        expect(EtOrbi.get_tzone(s)).to eq(nil)
      end
    end

    # rufus-scheduler gh-222
    #
    it "falls back to ENV['TZ'] if it doesn't know Time.now.zone" do

      begin

        current = EtOrbi.get_tzone(:local)

        Time._zone = '中国标准时间'

#        expect(
#          EtOrbi.get_tzone(:current)
#        ).to eq(nil)
#
#        expect(
#          EtOrbi.get_tzone(:current)
#        ).to eq(
#          EtOrbi.get_tzone(Time.now.zone)
#        )
  #
  # gh-240 introduces a way of finding the timezone by asking directly
  # to the system, so those do return a timezone...

        in_zone 'Asia/Shanghai' do

          expect(EtOrbi.get_tzone(:local))
            .to eq(EtOrbi.get_tzone('Asia/Shanghai'))
            .or eq(EtOrbi.get_tzone('Asia/Chongqing'))
        end

      ensure

        Time._zone = nil
      end

      expect(
        EtOrbi.get_tzone(:local)
      ).to eq(
        current
      )
    end

    [ # for rufus-scheduler gh-228

      [ 'Asia/Tokyo', 'Asia/Tokyo' ],
      [ 'Asia/Shanghai', 'Asia/Shanghai', 'Asia/Chongqing' ],
      [ 'Europe/Zurich', 'Europe/Zurich', 'Africa/Ceuta' ],
      [ 'Europe/London', 'Europe/London', 'Europe/Belfast' ]

    ].each do |zone, target0, target1|

      it "returns the current timezone for :current in #{zone}" do

        in_zone(zone) do

          expect(EtOrbi.get_tzone(:local))
            .to eq(EtOrbi.get_tzone(target0))
            .or eq(EtOrbi.get_tzone(target1 || target0))
        end
      end
    end

    it "doesn't mind being given a TZInfo::Timezone" do

      tz = ::TZInfo::Timezone.get('Zulu')
      class << tz
        def <=>(tz)
          #return nil unless tz.is_a?(Timezone)
          identifier <=> tz.identifier
        end
      end
        # simulate tzinfo 0.3.53 issue

      expect(
        EtOrbi.get_tzone(tz)
      ).to eq(
        ::TZInfo::Timezone.get('Zulu')
      )
    end
  end

  describe '.determine_local_tzone' do

    it 'favours the local timezone' do

      in_zone(:no_env_tz) do

        Time._zone = 'Cape Verde Standard Time'
        EtOrbi._os_zone = '' # force #os_tz to return nil

        expect(
          EtOrbi.determine_local_tzone.name
        ).to eq(
          'Atlantic/Cape_Verde'
        )
      end
    end

    it 'favours the local timezone' do

      in_zone('Europe/Berlin') do

        expect(EtOrbi.determine_local_tzone.name)
          .to eq('Europe/Berlin')
          .or eq('Africa/Ceuta')
      end
    end

    it 'favours the local timezone (Mitteleuropaeische Sommerzeit)' do

      in_zone(:no_env_tz) do

        Time._zone = "Mitteleurop\xE4ische Sommerzeit"
        EtOrbi._os_zone = '' # force #os_tz to return nil

        expect {
          EtOrbi.determine_local_tzone.name
        }.not_to raise_error
      end
    end

    it 'returns the local timezone' do

      in_zone('Europe/Berlin') do

        expect(EtOrbi.determine_local_tzone.name)
          .to eq('Europe/Berlin')
          .or eq('Africa/Ceuta')
      end
    end

    it 'returns the local timezone' do

      in_zone('America/Jamaica') do

        expect(EtOrbi.determine_local_tzone.name)
          .to eq('America/Jamaica')
          .or eq('America/Atikokan')
      end
    end

    it 'returns the Rails-provided Time.zone.tzinfo if available' do

      # http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html

      Time._as_zone =
        SpecActiveSupportTimeZone.new(::TZInfo::Timezone.get('Europe/Vilnius'))

      in_zone(:no_env_tz) do
        expect(EtOrbi.determine_local_tzone.class).to eq(::TZInfo::DataTimezone)
        expect(EtOrbi.determine_local_tzone.name).to eq('Europe/Vilnius')
      end
      in_zone('Asia/Tehran') do
        expect(EtOrbi.determine_local_tzone.class).to eq(::TZInfo::DataTimezone)
        expect(EtOrbi.determine_local_tzone.name).to eq('Asia/Tehran')
      end
    end
  end

  describe '.zone' do

    it 'is an alias to .determine_local_tzone' do

      in_zone(:no_env_tz) do

        Time._zone = 'Cape Verde Standard Time'
        EtOrbi._os_zone = '' # force #os_tz to return nil

        expect(
          EtOrbi.zone.name
        ).to eq(
          'Atlantic/Cape_Verde'
        )
      end
    end
  end

  describe '.now' do

    it 'returns a current, local EoTime instance' do

      in_zone 'Asia/Shanghai' do

        t = EtOrbi.now
        n = Time.now

        expect(t.seconds).to be_between((n - 1).to_f, (n + 1).to_f)

        expect(t.zone.name)
          .to eq('Asia/Shanghai')
          .or eq('Asia/Chongqing')
      end
    end
  end

  describe '.make_time' do

    it 'returns an EoTime instance as is' do

      t0 = EtOrbi.parse('2017-03-21 12:00:34 Asia/Ulan_Bator')
      t1 = EtOrbi.make_time(t0)

      expect(t1.class).to eq(::EtOrbi::EoTime)
      expect(t1).to eq(t0)
      expect(t1.object_id).to eq(t0.object_id)
    end

    it 'returns an EoTime instance as is' do

      t0 = EtOrbi.parse('2017-03-21 12:00:34 Asia/Ulan_Bator')
      t1 = EtOrbi.make_time(t0, t0.zone)

      expect(t1.class).to eq(::EtOrbi::EoTime)
      expect(t1).to eq(t0)
      expect(t1.object_id).to eq(t0.object_id)
    end

    [
      [ 'an EoTime instance',
        nil,
        lambda { EtOrbi.parse('2017-03-21 12:00:34 Asia/Ulan_Bator') },
        'ot 2017-03-21 12:00:34 +08:00 dst:false' ],

      [ 'a local time',
        'Asia/Tbilisi',
        lambda { Time.local(2016, 11, 01, 12, 30, 9) },
        'ot 2016-11-01 12:30:09 +04:00 dst:false' ],

      [ 'an UTC time',
        nil,
        Time.utc(2016, 11, 01, 12, 30, 9),
        'ot 2016-11-01 12:30:09 +00:00 dst:false' ],

      [ 'a Date instance',
        nil,
        Date.new(2016, 11, 01),
        lambda {
          EtOrbi::EoTime.new(
            Time.local(2016, 11, 01).to_f, nil
          ).to_debug_s } ],

      [ 'a String',
        nil,
        '2016-11-01 12:30:09',
        lambda {
          EtOrbi::EoTime.new(
            Time.local(2016, 11, 01, 12, 30, 9).to_f, nil) } ],

      [ 'a String',
        'America/Chicago',
        '2016-11-01 12:30:09',
        lambda {
          EtOrbi::EoTime.new(
            Time.local(2016, 11, 01, 12, 30, 9).to_f, nil) } ],

      [ 'a Zulu String',
        nil,
        '2016-11-01 12:30:09Z',
        EtOrbi::EoTime.new(Time.utc(2016, 11, 01, 12, 30, 9).to_f, 'Zulu') ],

      [ 'a ss+01:00 String',
        nil,
        '2016-11-01 12:30:09+01:00',
        'ot 2016-11-01 12:30:09 +01:00 dst:false' ],

      [ 'a ss-01 String',
        nil,
        '2016-11-01 12:30:09-01',
        'ot 2016-11-01 12:30:09 -01:00 dst:false' ],

      [ 'a String with an explicit time zone',
        nil,
        '2016-05-01 12:30:09 America/New_York',
        'ot 2016-05-01 12:30:09 -05:00 dst:true' ],

      [ 'a Numeric',
        nil,
        3600,
        lambda { [ Time.now + 3600 - 0.35, Time.now + 3600 + 0.35 ] } ],

      [ 'an array [ y, m, d, ... ]',
        'Europe/Moscow',
        [ [ 2017, 2, 28 ] ],
        'ot 2017-02-28 00:00:00 +03:00 dst:false' ],

      [ 'an array of args (y, m, d, ...)',
        'Europe/Moscow',
        [ 2017, 1, 31, 10 ],
        'ot 2017-01-31 10:00:00 +03:00 dst:false' ],

      [ 'an array of args and a zone as last arg',
        nil,
        [ 2017, 1, 31, 12, 'Europe/Moscow' ],
        'ot 2017-01-31 12:00:00 +03:00 dst:false' ],

      [ 'a string and a zone as last arg',
        nil,
        [ '2016-05-01 12:30:09', 'America/Chicago' ],
        'ot 2016-05-01 12:30:09 -06:00 dst:true' ],

      [ 'a string and an overriding zone as last arg',
        nil,
        [ '2016-05-01 11:30:09 America/New_York', 'America/Chicago' ],
        'ot 2016-05-01 11:30:09 -06:00 dst:true' ],

      [ 'an array of args and a TZInfo zone as last arg',
        nil,
        [ 2017, 1, 31, EtOrbi.get_tzone('Europe/Oslo') ],
        'ot 2017-01-31 00:00:00 +01:00 dst:false' ],

      [ 'a string and a TZInfo zone as last arg',
        nil,
        [ '2017-01-31 12:30', EtOrbi.get_tzone('Europe/Oslo') ],
        'ot 2017-01-31 12:30:00 +01:00 dst:false' ],

    ].each do |name, zone, args, expected|

      title = "turns #{name} into an EoTime instance"
      title += " in #{zone}" if zone

      it(title) do

        eot, exp =
          in_zone(zone) do

            as = args.is_a?(Proc) ? args.call : args

            t = as.is_a?(Array) ?
              EtOrbi.make_time(*as) :
              EtOrbi.make_time(as)
            x = expected.is_a?(Proc) ?
              expected.call :
              expected

#p [ :t, t ]
#p [ :x, x ]
#p [ :t, t.to_s ]
#p [ :x, x.to_s ]
            [ t, x ]
          end

        case exp
        when String then expect(eot.to_debug_s).to eq(exp)
        when Array then expect(eot).to be_between(*exp)
        else expect(eot).to eq(exp)
        end
      end
    end

#    it 'accepts a duration String'# do
##
##      expect(
##        EtOrbi.make_time('1h')
##      ).to be_between(
##        Time.now + 3600 - 1, Time.now + 3600 + 1
##      )
##    end
#  #
#  # String parsing is fugit's job. Et-orbi should be a dependency of
#  # fugit, not the other way around. When fugit is present, this
#  # spec should succeed, else it should not.

    it 'accepts a Rails TimeWithZone' do

      # http://api.rubyonrails.org/classes/ActiveSupport/TimeWithZone.html

      n = Time.now
      z = EtOrbi.get_tzone('Pacific/Easter')

      #t = ActiveSupport::TimeWithZone.new(n, z)
        #
      t = n
      t.instance_eval { @z = z }
      class << t; def time_zone; @z; end; end
        #
        # fake an ActiveSupport::TimeWithZone instance with a #time_zone

      eot = EtOrbi.make_time(t)

      expect(eot.class).to eq(EtOrbi::EoTime)
      expect(eot.seconds).to eq(t.to_f)
      expect(eot.zone).to eq(t.time_zone)
    end

    it 'rejects a Time in a non-local ambiguous timezone' do

      t = Time.local(2016, 11, 01, 12, 30, 9)
      class << t; def zone; 'CEST'; end; end

      in_zone 'Asia/Tbilisi' do

        expect {
          EtOrbi.make_time(t)
        }.to raise_error(
          ArgumentError, /\ACannot determine timezone from "CEST"/
        )
      end
    end

    it 'rejects unparseable input' do

      expect {
        EtOrbi.make_time('xxx')
      #}.to raise_error(ArgumentError, 'couldn\'t parse "xxx"')
      }.to raise_error(ArgumentError, 'No time information in "xxx"')
        # straight out of Time.parse()

      expect {
        EtOrbi.make_time(Object.new)
      }.to raise_error(ArgumentError, /\ACannot turn /)
    end
  end

  describe '.to_windows_tz' do

    {

      [ 'Asia/Tokyo', Time.local(2018, 5, 23) ] => 'JST-9',
      [ 'Asia/Kolkata', Time.local(2018, 7, 1) ] => 'IST-5:30',
      [ 'Europe/Berlin', Time.local(2018, 1, 1) ] => 'CET-1CEST',
      [ 'Europe/Berlin', Time.local(2018, 7, 1) ] => 'CET-2CEST',
      [ 'America/New_York', Time.local(2018, 1, 1) ] => 'EST5EDT',
      [ 'America/New_York', Time.local(2018, 7, 1) ] => 'EST4EDT',

    }.each do |(zone, time), v|

      it "returns #{v.inspect} for #{zone.inspect} at #{time}" do

        expect(EtOrbi.to_windows_tz(zone, time)).to eq(v)
      end
    end
  end
end

