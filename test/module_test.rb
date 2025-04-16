# encoding: UTF-8

#
# Testing EtOrbi
#
# Wed Mar 11 21:17:36 JST 2015, quatre ans... (rufus-scheduler)
# Sun Mar 19 05:16:28 JST 2017
# Fri Mar 24 04:55:25 JST 2017 圓さんの家
#


group EtOrbi do

  before do

    ENV['TZ'] = ENV['_TZ']
    Time._zone = nil
    EtOrbi._os_zone = nil
    Time.active_support_zone = nil
  end

  group '.list_iso8601_zones' do

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

      test "returns #{zones.inspect} for #{string.inspect}" do

        assert EtOrbi.list_iso8601_zones(string), zones
      end
    end
  end

#  group '.list_olson_zones' do
#
#    [
#
#      [ '11/09/2002 America/New_York',
#        %w[ America/New_York ] ],
#      [ '11/09/2002 America/New_York Asia/Shanghai',
#        %w[ America/New_York Asia/Shanghai ] ],
#      [ 'America/New_York Asia/Shanghai',
#        %w[ America/New_York Asia/Shanghai ] ],
#      [ '2018-09-04 07:54:58 Etc/GMT-11',
#        %w[ Etc/GMT-11 ] ],
#
#      [ '2018-09-04 07:54:58 UTC+11',
#        %w[ UTC+11 ] ],
#      [ '2018-09-04 07:54:58 UTC+11 Etc/GMT-11',
#        %w[ Etc/GMT-11 UTC+11 ] ],
#          #
#          # https://github.com/floraison/fugit/issues/9
#
#      [ '11/09/2002 2utopiaNada?3Nada',
#        [] ]
#
#    ].each do |string, zones|
#
#      test "returns #{zones.inspect} for #{string.inspect}" do
#
#        assert EtOrbi.list_olson_zones(string), zones)
#      end
#    end
#  end

  group '.extract_zone' do

    [

      [ '2016-11-01 12:30:09-01', [ '2016-11-01 12:30:09', '-01' ] ],
      [ '2016-11-01 12:30:09-01:00', [ '2016-11-01 12:30:09', '-01:00' ] ],
      [ '2016-11-01 12:30:09 -01', [ '2016-11-01 12:30:09', '-01' ] ],
      [ '2016-11-01 12:30:09 -01:00', [ '2016-11-01 12:30:09', '-01:00' ] ],
      [ '2016-11-01 12:30:09-01:30', [ '2016-11-01 12:30:09', '-01:30' ] ],
      [ '2016-11-01 12:30:09 -01:30', [ '2016-11-01 12:30:09', '-01:30' ] ],

      [ '11/09/2002 America/New_York',
        [ '11/09/2002', 'America/New_York' ] ],
      [ '11/09/2002 America/New_York Asia/Shanghai',
        [ '11/09/2002', 'Asia/Shanghai' ] ],
      [ 'America/New_York Asia/Shanghai',
        [ '', 'Asia/Shanghai' ] ],
      [ '2018-09-04 07:54:58 Etc/GMT-11',
        [ '2018-09-04 07:54:58', 'Etc/GMT-11' ] ],
      [ '2018-09-04 07:54:58 UTC+11',
        [ '2018-09-04 07:54:58', 'UTC+11' ] ],
      [ '2018-09-04 07:54:58 UTC+11 Etc/GMT-11',
        [ '2018-09-04 07:54:58', 'Etc/GMT-11' ] ],

      [ 'Sun Nov 18 16:01:00 Asia/Singapore 2012',
        [ 'Sun Nov 18 16:01:00  2012', 'Asia/Singapore' ] ],

      [ '2016-11-01 12:30:09', [ '2016-11-01 12:30:09', nil ] ],
      [ '2016-11-01 12:30:09-25', [ '2016-11-01 12:30:09-25', nil ] ],
      [ '2016-11-01 12:30:09-25:00', [ '2016-11-01 12:30:09-25:00', nil ] ],

      [ '11/09/2002 2utopiaNada?3Nada',
        [ '11/09/2002 2utopiaNada?3Nada', nil ] ],

      [ '2012-10-28 03:00:00 EET',
        [ '2012-10-28 03:00:00', 'EET' ] ],
      #[ '2012-10-28 03:00:00 EEST',
      #  [ '2012-10-28 03:00:00', 'EEST' ] ],
      [ '2012-10-28 03:00:00 Europe/Tallinn',
        [ '2012-10-28 03:00:00', 'Europe/Tallinn' ] ],

    ].each { |str0, (str1, zone)|

      test "returns #{[ str1, zone ].inspect} for #{str0.inspect}" do

        s1, z = EtOrbi.extract_zone(str0)

        assert [ s1, z ], [ str1, zone ]
      end
    }
  end

  group '.parse' do

    test 'parses a time string without a timezone' do

      ot = in_zone('Europe/Moscow') { EtOrbi.parse('2015/03/08 01:59:59') }

      t = ot
      u = ot.utc

      assert t.to_i, 1425769199
      assert u.to_i, 1425769199

      assert(
        t.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{t.isdst}",
        '2015/03/08 01:59:59 MSK +0300 false')

      assert u.to_debug_s, 't 2015-03-07 22:59:59 +00:00 dst:false'
    end

    test 'parses a time string with a full name timezone' do

      ot = EtOrbi.parse('2015/03/08 01:59:59 America/Los_Angeles')

      t = ot
      u = ot.utc

      assert t.to_i, 1425808799
      assert u.to_i, 1425808799

      assert t.to_debug_s, 'ot 2015-03-08 01:59:59 -08:00 dst:false'
      assert u.to_debug_s, 't 2015-03-08 09:59:59 +00:00 dst:false'
    end

    test 'parses a time string with a delta timezone' do

      ot = in_zone('Europe/Berlin') { EtOrbi.parse('2015-12-13 12:30 -0200') }

      t = ot
      u = ot.utc

      assert t.to_i, 1450017000
      assert u.to_i, 1450017000

      assert t.to_debug_s, 'ot 2015-12-13 12:30:00 -02:00 dst:false'
      assert u.to_debug_s, 't 2015-12-13 14:30:00 +00:00 dst:false'
    end

    test 'parses a time string with a delta (:) timezone' do

      ot = in_zone('Europe/Berlin') { EtOrbi.parse('2015-12-13 12:30 -02:00') }

      t = ot
      u = ot.utc

      assert t.to_i, 1450017000
      assert u.to_i, 1450017000

      assert t.to_debug_s, 'ot 2015-12-13 12:30:00 -02:00 dst:false'
      assert u.to_debug_s, 't 2015-12-13 14:30:00 +00:00 dst:false'
    end

    test 'takes the local TZ when test does not know the timezone' do

      in_zone 'Europe/Moscow' do

        ot = EtOrbi.parse('2015/03/08 01:59:59 Nada/Nada')

        assert_include ot.zone.name, %w[ Europe/Moscow Europe/Kirov ]
      end
    end

    test 'parses even when the tz is out of place' do

      assert(
        EtOrbi.parse('Sun Nov 18 16:01:00 Asia/Singapore 2012')
          .to_debug_s,
        "ot 2012-11-18 16:01:00 +08:00 dst:false")
    end

    test 'fails on invalid strings' do

      assert_error(
        lambda { EtOrbi.parse('xxx') },
        ArgumentError, 'No time information in "xxx"')
    end

    test 'parses in the Rails-provided Time.zone (UTC)' do

      Time.active_support_zone = 'UTC'

      t = EtOrbi.parse('2019-01-01 12:10')

      assert t.class, EtOrbi::EoTime
      assert t.zone, ::TZInfo::Timezone.get('UTC')
      assert t.to_s, '2019-01-01 12:10:00 Z'
      assert t.to_zs, '2019-01-01 12:10:00 UTC'
    end

    test 'parses in the Rails-provided Time.zone (Asia/Shanghai)' do

      Time.active_support_zone = 'Asia/Shanghai'

      t = EtOrbi.parse('2019-01-01 12:10')

      assert t.class, EtOrbi::EoTime
      assert t.zone, ::TZInfo::Timezone.get('Asia/Shanghai')
      assert t.to_s, '2019-01-01 12:10:00 +0800'
      assert t.to_zs, '2019-01-01 12:10:00 Asia/Shanghai'
    end

#    # https://en.wikipedia.org/wiki/List_of_time_zone_abbreviations
#    # https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
#
#    context 'TZ abbreviations' do
#
#      {
#
#        '2021-01-01 7AM America/Los_Angeles' => '2021-01-01 07:00:00 -0800',
#        '2021-07-01 7AM America/Los_Angeles' => '2021-07-01 07:00:00 -0700',
#        '2021-01-01 7AM PST' =>                 '2021-01-01 07:00:00 -0800',
#        '2021-07-01 7AM PDT' =>                 '2021-07-01 07:00:00 -0700',
#        '2021-01-01 7AM -07:00' =>              '2021-01-01 07:00:00 -0700',
#        '2021-07-01 7AM -07:00' =>              '2021-07-01 07:00:00 -0700',
#        '2021-01-01 7AM GMT-7' =>               '2021-01-01 07:00:00 -0700',
#        '2021-07-01 7AM GMT-7' =>               '2021-07-01 07:00:00 -0700',
#        '2021-01-01 7AM UTC-7' =>               '2021-01-01 07:00:00 -0700',
#        '2021-07-01 7AM UTC-7' =>               '2021-07-01 07:00:00 -0700',
#        '2021-01-01 7AM Etc/GMT-7' =>           '2021-01-01 07:00:00 -0700',
#        '2021-07-01 7AM Etc/GMT-7' =>           '2021-07-01 07:00:00 -0700',
#
#        '2021-01-01 7AM ACDT' => '2021-01-01 07:00:00 +0930',
#        '2021-07-01 7AM ACST' => '2021-01-01 07:00:00 +1030',
#
#      }.each do |k, v|
#
#        test "parses #{k} to #{v}" do
#
#          ot = EtOrbi.parse(k)
#t = Time.parse(k)
#p [ k ]
#p [ Date._parse(k) ]
#p [ t.to_s, t.zone, :t ]
#p [ ot.to_s, ot.zone, :ot ]
#p [ v ]
#  #p [ k, v, ot ]
#
#          assert ot.to_s, v)
#        end
#      end
#    end

    group 'when Chronic is defined' do

      before do
        require_chronic
      end
      after do
        unrequire_chronic
      end

      test 'leverages it' do

        t = EtOrbi.parse('tomorrow at 1pm')
        t1 = Time.now + 24 * 3600

        assert t.class, EtOrbi::EoTime
        assert t.strftime('%F %T'), t1.strftime('%F 13:00:00')
      end

      test 'leverages test in a specified time zone' do

        t = EtOrbi.parse('tomorrow at 22:00 America/New_York')
        t1 = Time.now + 24 * 3600

        assert t.class, EtOrbi::EoTime
        assert t.to_zs, t1.strftime('%F 22:00:00 America/New_York')
      end

      test 'picks the Rails Time.zone (UTC) if available' do

        Time.active_support_zone = 'UTC'

        t = EtOrbi.parse('tomorrow')
        t1 = Time.now + 24 * 3600

        assert t.class, EtOrbi::EoTime
        assert t.zone.name, 'UTC'
        assert t.strftime('%Y-%m-%d'), t1.strftime('%Y-%m-%d')
        assert t.strftime('%H:%M:%S'), '12:00:00'
      end

      test 'picks the Rails Time.zone (Asia/Shanghai) if available' do

        Time.active_support_zone = 'Asia/Shanghai'

        t = EtOrbi.parse('tomorrow')
        t1 = Time.now + 24 * 3600

        assert t.class, EtOrbi::EoTime
        assert t.zone.name, 'Asia/Shanghai'
        assert t.strftime('%Y-%m-%d'), t1.strftime('%Y-%m-%d')
        assert t.strftime('%H:%M:%S'), '12:00:00'
      end

      group 'when parse(x, enable_chronic: false)' do

        test 'does not pre-parse with Chronic' do

          Time.active_support_zone = 'America/Chicago'

          assert( # works
            EtOrbi.parse('tomorrow').class,
            EtOrbi::EoTime)

          assert_error( # doesn't work
            lambda { EtOrbi.parse('tomorrow', enable_chronic: false) },
            ArgumentError, 'No time information in "tomorrow"')
        end
      end

      group 'and Et-Orbi.chronic_enabled? is false' do

        before do
          EtOrbi.chronic_enabled = false
        end
        after do
          EtOrbi.chronic_enabled = true
        end

        test 'does not pre-parse with Chronic' do

          assert_error(
            lambda { EtOrbi.parse('tomorrow') },
            ArgumentError, 'No time information in "tomorrow"')
        end

        test 'pre-parses with Chronic when enable_chronic: true' do

          assert_not_error { EtOrbi.parse('tomorrow', enable_chronic: true) }
        end
      end

      test 'filters options given to Chronic' do

        Time.active_support_zone = 'UTC'

        #assert ::Khronic)
        #  .to receive(:parse)
        #  .with('tomorrow', { context: :future })
        #  .and_call_original

        t = EtOrbi.parse(
          'tomorrow', zone: ::TZInfo::Timezone.get('UTC'), context: :future)
        t1 = Time.now + 24 * 3600

        assert t.class, EtOrbi::EoTime
        assert t.zone.name, 'UTC'
        assert t.strftime('%Y-%m-%d'), t1.strftime('%Y-%m-%d')
        assert t.strftime('%H:%M:%S'), '12:00:00'
      end
    end
  end

  group '.get_tzone' do

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

      '_AT-3:30Asia/Tehran' => 'Asia/Tehran',
      '_AT-4Asia/Tbilisi' => 'Asia/Tbilisi',

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

      'WET-1WEST' => 'WET',
      'CET-2CEST' => 'CET',

    }.each do |a, b|

      test "returns #{b.inspect} for #{a.inspect}" do

        z = EtOrbi.get_tzone(a)

        assert_not_nil z
        assert z.name, b
      end
    end

#    test 'returns a timezone for well-known abbreviations' do
#
#      assert gtz('JST'), 'Japan'
#      assert gtz('PST'), 'America/Dawson'
#      assert gtz('CEST'), 'Africa/Ceuta'
#    end

    [
      'Asia/Paris', 'Nada/Nada', '7', '06', 'sun#3', 'Mazda Zoom Zoom Stadium'
    ].each do |s|

      test "returns nil for #{s.inspect}" do

        assert_nil EtOrbi.get_tzone(s)
      end
    end

    # rufus-scheduler gh-222
    #
    test "falls back to ENV['TZ'] if test doesn't know Time.now.zone" do

      begin

        current = EtOrbi.get_tzone(:local)

        Time._zone = '中国标准时间'

        #assert_nil EtOrbi.get_tzone(:current)
        #assert EtOrbi.get_tzone(:current), EtOrbi.get_tzone(Time.now.zone)
          #
          # gh-240 introduces a way of finding the timezone by asking directly
          # to the system, so those do return a timezone...

        in_zone 'Asia/Shanghai' do

          assert_include(
            EtOrbi.get_tzone(:local),
            [ EtOrbi.get_tzone('Asia/Shanghai'),
              EtOrbi.get_tzone('Asia/Chongqing') ])
        end

      ensure

        Time._zone = nil
      end

      assert EtOrbi.get_tzone(:local), current
    end

    { # for rufus-scheduler gh-228

      'Asia/Tokyo' => %w[
        Asia/Tokyo ],
      'Asia/Shanghai' => %w[
        Asia/Shanghai Asia/Chongqing ],
      'Europe/Zurich' => %w[
        Europe/Zurich Africa/Ceuta windows:CET ],
      'Europe/London' => %w[
        Europe/London Europe/Belfast windows:GMT windows:GMT-0 ],

    }.each do |zone, targets|

      test "returns the current timezone for :current in #{zone}" do

        in_zone(zone) do

          assert_include EtOrbi.get_tzone(:local), select_zones(targets)
        end
      end
    end

    test "doesn't mind being given a TZInfo::Timezone" do

      tz = ::TZInfo::Timezone.get('Zulu')
      class << tz
        def <=>(tz)
          #return nil unless tz.is_a?(Timezone)
          identifier <=> tz.identifier
        end
      end
        # simulate tzinfo 0.3.53 issue

      assert EtOrbi.get_tzone(tz), ::TZInfo::Timezone.get('Zulu')
    end
  end

  group '.determine_local_tzone' do

    test 'favours the local timezone' do

      in_zone(:no_env_tz) do

        Time._zone = 'Cape Verde Standard Time'
        EtOrbi._os_zone = '' # force #os_tz to return nil

        assert EtOrbi.determine_local_tzone.name, 'Atlantic/Cape_Verde'
      end
    end

    test 'favours the local timezone' do

      in_zone('Europe/Berlin') do

        assert_include(
          EtOrbi.determine_local_tzone,
          select_zones(%w[ Europe/Berlin Africa/Ceuta windows:CET ]))
      end
    end

    test 'favours the local timezone (Mitteleuropaeische Sommerzeit)' do

      in_zone(:no_env_tz) do

        Time._zone = "Mitteleurop\xE4ische Sommerzeit"
        EtOrbi._os_zone = '' # force #os_tz to return nil

        assert_not_error { EtOrbi.determine_local_tzone }
      end
    end

    test 'returns the local timezone' do

      in_zone('America/Jamaica') do

        assert_include(
          EtOrbi.determine_local_tzone.name,
          [ 'America/Jamaica', 'America/Atikokan', 'EST' ])
      end
    end

    test 'returns the Rails-provided Time.zone.tzinfo if available' do

      # http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html

      Time.active_support_zone = 'Europe/Vilnius'

      in_zone(:no_env_tz) do
        assert EtOrbi.determine_local_tzone.class, ::TZInfo::DataTimezone
        assert EtOrbi.determine_local_tzone.name, 'Europe/Vilnius'
      end
    end

    test "gives precedence to ENV['TZ'] over Rails Time.zone.tzinfo" do

      # http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html

      Time.active_support_zone = 'Europe/Vilnius'

      in_zone('Asia/Tehran') do

        assert EtOrbi.determine_local_tzone.class, ::TZInfo::DataTimezone
        assert EtOrbi.determine_local_tzone.name, 'Asia/Tehran'
      end
    end
  end

  group '.zone' do

    test 'is an alias to .determine_local_tzone' do

      in_zone(:no_env_tz) do

        Time._zone = 'Cape Verde Standard Time'
        EtOrbi._os_zone = '' # force #os_tz to return nil

        assert EtOrbi.zone.name, 'Atlantic/Cape_Verde'
      end
    end
  end

  group '.now' do

    test 'returns a current, local EoTime instance' do

      in_zone 'Asia/Shanghai' do

        t = EtOrbi.now
        n = Time.now

        assert t.seconds > (n - 1).to_f
        assert t.seconds < (n + 1).to_f

        assert_include t.zone.name, [ 'Asia/Shanghai', 'Asia/Chongqing' ]
      end
    end
  end

  group '.make_time' do

    test 'returns an EoTime instance as is' do

      t0 = EtOrbi.parse('2017-03-21 12:00:34 Asia/Ulan_Bator')
      t1 = EtOrbi.make_time(t0)

      assert t1.class, ::EtOrbi::EoTime
      assert t1, t0
      assert t1.object_id, t0.object_id
    end

    test 'returns an EoTime instance as is' do

      t0 = EtOrbi.parse('2017-03-21 12:00:34 Asia/Ulan_Bator')
      t1 = EtOrbi.make_time(t0, t0.zone)

      assert t1.class, ::EtOrbi::EoTime
      assert t1, t0
      assert t1.object_id, t0.object_id
    end

    [
      [ 'an EoTime instance',
        nil,
        lambda { EtOrbi.parse('2017-03-21 12:00:34 Asia/Ulan_Bator') },
        'ot 2017-03-21 12:00:34 +08:00 dst:false' ],

      [ 'a local time',
        'Asia/Tbilisi',
        Time.parse('2016-11-01 12:30:09 +04:00'), # use custom tz :-(
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
        '2016-08-01 12:30:10',
        'ot 2016-08-01 12:30:10 -05:00 dst:true' ],
      #[ 'a String',
      #  'America/Chicago',
      #  '2016-11-01 12:30:09',
      #  'ot 2016-11-01 12:30:09 -05:00 dst:true' ], # fails on Appveyor :-(
      [ 'a String',
        'America/Chicago',
        '2016-11-06 12:30:08',
        'ot 2016-11-06 12:30:08 -06:00 dst:false' ],

      [ 'a String',
        'Europe/Paris',
        '2016-1-1 12:30:07',
        'ot 2016-01-01 12:30:07 +01:00 dst:false' ],
      [ 'a String',
        'Europe/Paris',
        '2016-8-1 12:30:07',
        'ot 2016-08-01 12:30:07 +02:00 dst:true' ],

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
        'ot 2016-05-01 12:30:09 -04:00 dst:true' ],

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
        'ot 2016-05-01 12:30:09 -05:00 dst:true' ],

      [ 'a string and an overriding zone as last arg',
        nil,
        [ '2016-05-01 11:30:09 America/New_York', 'America/Chicago' ],
        'ot 2016-05-01 11:30:09 -05:00 dst:true' ],

      [ 'an array of args and a TZInfo zone as last arg',
        nil,
        [ 2017, 1, 31, EtOrbi.get_tzone('Europe/Oslo') ],
        'ot 2017-01-31 00:00:00 +01:00 dst:false' ],

      [ 'a string and a TZInfo zone as last arg',
        nil,
        [ '2017-01-31 12:30', EtOrbi.get_tzone('Europe/Oslo') ],
        'ot 2017-01-31 12:30:00 +01:00 dst:false' ],

      [ 'a string',
        'America/Chicago',
        lambda { [ Time.parse('2021-03-11') ] },
        windows? ? 'CST6CDT' : 'America - Chicago',
        lambda { |t| t.zone.to_s } ],

      [ 'a string',
        'America/New_York',
        lambda { [ Time.parse('2021-03-11') ] },
        windows? ? %w[ EST5EDT EST ] : 'America - New York',
        #windows? ? 'EST' : 'America - New York',
        lambda { |t| t.zone.to_s } ],

    ].each do |name, zone, args, asserted, transformer|

      title = "turns #{name} into an EoTime instance"
      title += " in #{zone}" if zone

      test(title) do

        eot, exp =
          in_zone(zone) do

            as = args.is_a?(Proc) ? args.call : args

            t = as.is_a?(Array) ?
              EtOrbi.make_time(*as) :
              EtOrbi.make_time(as)
            x = asserted.is_a?(Proc) ?
              asserted.call :
              asserted

            t = transformer.is_a?(Proc) ? transformer[t] : t

            [ t, x ]
          end
#p eot.to_debug_s
#p eot.utc_offset
#p eot.send(:to_time).to_s
#p eot.send(:to_time).utc_offset

        case exp
        when String
          assert eot.respond_to?(:to_debug_s) ? eot.to_debug_s : eot, exp
        when Array
          if exp.collect(&:class).uniq == [ String ]
            assert exp.include?(eot)
          else
            assert eot > exp[0]
            assert eot < exp[1]
          end
        else
          assert eot, exp
        end
      end
    end

#    test 'accepts a duration String'# do
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
#  # spec should succeed, else test should not.

    test 'accepts a Rails TimeWithZone' do

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

      assert eot.class, EtOrbi::EoTime
      assert eot.seconds, t.to_f
      assert eot.zone, t.time_zone
    end

    test 'rejects a Time in a non-local ambiguous timezone' do

      t = Time.local(2016, 11, 01, 12, 30, 9)
      class << t; def zone; 'ECT'; end; end

      in_zone 'Asia/Tbilisi' do

        assert_error(
          lambda { EtOrbi.make_time(t) },
          ArgumentError, /\ACannot determine timezone from "ECT"/)
      end
    end

    test 'rejects unparsable input' do

      assert_error(
        lambda { EtOrbi.make_time('xxx') },
        ArgumentError, 'No time information in "xxx"')
          #
          # straight out of Time.parse()

      assert_error(
        lambda { EtOrbi.make_time(Object.new) },
        ArgumentError, /\ACannot turn /)
    end
  end

  group '.windows_zone_name' do

    { [ 'Asia/Tokyo', '2018-05-23' ] => 'JST-9',
      [ 'Asia/Kolkata', '2018-07-01' ] => 'IST-5:30',
      [ 'Asia/Tehran', '2019-01-09' ] => '_AT-3:30Asia/Tehran', #'IRT-3:30',
      [ 'Asia/Tehran', '2019-07-09' ] => '_AT-4:30Asia/Tehran', #'IRT-4:30',
      [ 'Asia/Tbilisi', '2019-01-09' ] => '_AT-4:00Asia/Tbilisi',
      [ 'Asia/Samarkand', '2017-11-01' ] => '_AS-5:00Asia/Samarkand',
      [ 'Europe/Berlin', '2018-01-01' ] => 'CET-1CEST',
      [ 'Europe/Berlin', '2018-07-01' ] => 'CET-2CEST',
      [ 'America/New_York', '2018-01-01' ] => 'EST5EDT',
      [ 'America/New_York', '2018-07-01' ] => 'EST4EDT',
      [ 'America/Los_Angeles', '2017-10-30' ] => 'PST7PDT',
      [ 'America/Los_Angeles', '2019-01-01' ] => 'PST8PDT',

      [ 'Europe/Tallinn', '2012-07-28' ] => 'EET-3EEST',
      [ 'Europe/Tallinn', '2012-10-28' ] => 'EET-3EEST',
      [ 'Europe/Tallinn', '2012-12-28' ] => 'EET-2EEST',

    }.each do |(zone, time), v|

      test "returns #{v.inspect} for #{zone.inspect} at #{time}" do

        assert EtOrbi.windows_zone_name(zone, Time.parse(time)), v
      end
    end
  end

  group '.zone_abbreviation' do

    { [ 'Europe/Tallinn', '2012-07-28' ] => 'EEST',
      [ 'Europe/Tallinn', '2012-10-28' ] => 'EEST',
      [ 'Europe/Tallinn', '2012-12-28' ] => 'EET',

      [ 'Europe/Tallinn', '2012-03-25 02:00' ] => 'EET',
      [ 'Europe/Tallinn', '2012-03-25 03:00' ] => 'EEST',
      [ 'Europe/Tallinn', '2012-03-25 04:00' ] => 'EEST',
      [ 'Europe/Tallinn', '2012-03-25 05:00' ] => 'EEST',

      [ 'Europe/Tallinn', '2012-10-28 00:00' ] => 'EEST',
      [ 'Europe/Tallinn', '2012-10-28 02:59' ] => 'EEST',
      [ 'Europe/Tallinn', '2012-10-28 03:00' ] => 'EET',
      [ 'Europe/Tallinn', '2012-10-28 03:30' ] => 'EET',
      [ 'Europe/Tallinn', '2012-10-28 04:30' ] => 'EET',

      # in case of ambiguity, .zone_abbreviation goes 2 hours forward...

    }.each do |(zone, time), v|

      test "returns #{v.inspect} for #{zone.inspect} at #{time}" do

        assert EtOrbi.zone_abbreviation(zone, Time.parse(time)), v
      end
    end
  end

  group '.tweak_zone_name' do

    { 'EST5EDT' => 'EST5EDT',
      'UTC+12' => 'Etc/GMT-12',
      'Korea Standard Time' => 'Asia/Seoul',

    }.each do |n0, n1|

      test "turns #{n0.inspect} into #{n1.inspect}" do

        assert EtOrbi.tweak_zone_name(n0), n1
      end
    end
  end

  group '.chronic_enabled?' do

    test 'returns true by default' do

      assert EtOrbi.chronic_enabled?
    end
  end

  group '.chronic_enabled=' do

    after do
      EtOrbi.chronic_enabled = true
    end

    test 'lets disable chronic parsing' do

      EtOrbi.chronic_enabled = false

      assert_false EtOrbi.chronic_enabled?
    end
  end

#  group '.abbreviate_zone_name' do
#
#    {
#
#      'EST5EDT' => 'EST5EDT',
#      'BST' => %w[ GB-Eire GB ],
#      'UTC+12' => nil,
#
#    }.each do |n0, n1|
#
#      n1s = n1.inspect
#      n1s = n1.collect(&:inspect).join(' or ') if n1.is_a?(Array)
#
#      test "turns #{n0.inspect} into #{n1s}" do
#
#        if n1.is_a?(Array)
#          assert n1).to include(EtOrbi.abbreviate_zone_name(n0))
#        else
#          assert EtOrbi.abbreviate_zone_name(n0), n1)
#        end
#      end
#    end
#  end
end

