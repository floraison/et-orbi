# encoding: UTF-8

#
# Specifying EtOrbi
#
# Wed Mar 11 21:17:36 JST 2015, quatre ans... (rufus-scheduler)
# Sun Mar 19 05:16:28 JST 2017
#


group EtOrbi::EoTime do

  group '.new' do

    group "zone 'America/Los_Angeles'" do

      test 'accepts an integer' do

        ot = EtOrbi::EoTime.new(1234567890, 'America/Los_Angeles')

        assert ot.seconds.to_i, 1234567890
        assert ot.zone.name, 'America/Los_Angeles'
      end

      test 'accepts a float' do

        ot = EtOrbi::EoTime.new(1234567890.1234, 'America/Los_Angeles')

        assert ot.seconds.to_i, 1234567890
        assert ot.zone.name, 'America/Los_Angeles'
      end

      test 'accepts a UTC ::Time instance' do

        ot =
          EtOrbi::EoTime.new(
            Time.utc(2007, 11, 1, 15, 25, 0),
            'America/Los_Angeles')

        assert ot.seconds.to_i, 1193930700
        assert ot.zone.name, 'America/Los_Angeles'
      end

      test 'accepts a UTC EtOrbi::EoTime instance' do

        ot =
          EtOrbi::EoTime.new(
            EtOrbi::EoTime.new(1193930700, 'UTC'),
            'America/Los_Angeles')

        assert ot.seconds.to_i, 1193930700
        assert ot.zone.name, 'America/Los_Angeles'
      end

      test 'accepts a local ::Time instance' do

        #in_zone 'Asia/Samarkand' do
        #
        #  t = Time.parse('2007-11-01 15:25')
        #  ot = EtOrbi::EoTime.new(t, 'America/Los_Angeles')
        #
        #  assert ot.seconds, t.to_i)
        #  assert ot.seconds.to_i, 1193912700)
        #  assert ot.zone.name, 'America/Los_Angeles')
        #end
          #
          # because of https://ci.appveyor.com/project/jmettraux/et-orbi/build/job/8birnr0k54jrihx8

        t = Time.parse('2007-11-01 15:25 +05:00')
          # use a local ::Time instance with a custom timezone :-(

        ot = EtOrbi::EoTime.new(t, 'America/Los_Angeles')

        assert ot.seconds, t.to_i
        assert ot.seconds.to_i, 1193912700
        assert ot.zone.name, 'America/Los_Angeles'
      end

      test 'accepts a Local EtOrbi::EoTime instance' do

        ot =
          EtOrbi::EoTime.new(
            EtOrbi::EoTime.new(1193930700, 'Asia/Yekaterinburg'),
            'America/Los_Angeles')

        assert ot.seconds.to_i, 1193930700
        assert ot.zone.name, 'America/Los_Angeles'
      end
    end

    group "zone TZInfo instance 'Europe/Paris'" do

      test 'accepts an integer' do

        ot = EtOrbi::EoTime
          .new(1234567890, ::TZInfo::Timezone.get('Europe/Paris'))

        assert ot.seconds.to_i, 1234567890
        assert ot.zone.name, 'Europe/Paris'
      end
    end

    group "zone ActiveSupport::TimeZone instance 'America/New_York'" do

      test 'accepts an integer' do

        ot = EtOrbi::EoTime
          .new(1234567890, TestActiveSupportTimeZone.make('America/New_York'))

        assert ot.seconds.to_i, 1234567890
        assert ot.zone.name, 'America/New_York'
      end
    end
  end

  group '.utc' do

    [

      [ [ 2017, 3, 25 ], '2017-03-25T00:00:00Z' ],
      [ [ 2017, 3, 25, 21, 23, 29 ], '2017-03-25T21:23:29Z' ],

    ].each do |a, s|

      test "accepts #{a.inspect}" do

        ot = EtOrbi::EoTime.utc(*a)

        assert ot.class, EtOrbi::EoTime
        assert ot.zone.name, 'UTC'
        assert ot.iso8601, s
      end
    end
  end

  group '.local' do

    [

      [ [ 2017, 3, 25 ],
        %w[ Europe/Lisbon windows:WET Atlantic/Canary ],
        '2017-03-25T00:00:00+00:00' ],
      [ [ 2017, 3, 25, 21, 23, 29 ],
        %w[ Europe/Lisbon windows:WET Atlantic/Canary ],
        '2017-03-25T21:23:29+00:00' ],
      [ [ 2017, 3, 25, 21, 23, 29 ],
        %w[ Europe/Moscow Europe/Kirov ],
        '2017-03-25T21:23:29+03:00' ],

    ].each do |a, zs, s|

      test "accepts #{a.inspect} in #{zs.first}" do

        in_zone(zs.first) do

          ot = EtOrbi::EoTime.local(*a)

          assert ot.class, EtOrbi::EoTime
          assert_include ot.zone, select_zones(zs)
          assert ot.iso8601, s
        end
      end
    end
  end

  group '#to_time (protected)' do

    if TZInfo::Timezone
       .get('America/Los_Angeles')
       .utc_to_local(Time.at(1193898300))
       .utc?
    then
      # TZInfo < 2.0.0

      test 'returns a local Time instance, although with a UTC zone' do

        ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
        t = ot.send(:to_time)

        assert ot.to_debug_s, 'ot 2007-10-31 23:25:00 -07:00 dst:true'

        assert t.to_i, 1193898300 - 7 * 3600 # /!\
        assert t.utc_offset, 0

        assert t.to_debug_s, 't 2007-10-31 23:25:00 +00:00 dst:false'
          # Time instance stuck to UTC...
      end

    else
      # TZInfo >= 2.0.0

      test 'returns a local Time instance' do

        ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
        t = ot.send(:to_time)

        assert ot.to_debug_s, 'ot 2007-10-31 23:25:00 -07:00 dst:true'

        assert t.to_i, 1193898300
        assert t.utc_offset, -7 * 3600

        assert t.to_debug_s, 't 2007-10-31 23:25:00 -07:00 dst:true'
      end
    end
  end

  group '#to_local_time' do

    test 'returns a local Time instance in the local time zone' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      t = ot.to_local_time

      assert t.class, ::Time
      assert t.to_i, 1193898300
      assert t.usec, 0

      t1 = Time.parse(t.strftime("%Y-%m-%d %H:%M:%S.#{'%06d' % t.usec}"))
      assert t.to_s, t1.to_s
    end
  end

  group '#to_t' do

    test 'is an alias to #to_local_time' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      t = ot.to_t

      assert t.class, ::Time
      assert t.to_i, 1193898300
      assert t.usec, 0
    end
  end

  group '#to_utc_time' do

    test 'is an alias to #to_utc' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      ut = ot.to_utc_time

      assert ut.class, ::Time
      assert ut.to_i, 1193898300
      assert ut.usec, 0

      assert ut.to_s, '2007-11-01 06:25:00 UTC'
    end
  end

  group '#utc' do

    test 'returns an UTC Time instance' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      ut = ot.utc

      assert ut.to_i, 1193898300

      assert ot.to_debug_s, 'ot 2007-10-31 23:25:00 -07:00 dst:true'
      assert ut.to_debug_s, 't 2007-11-01 06:25:00 +00:00 dst:false'
    end
  end

  group '#utc?' do

    test 'returns true if the EoTime zone is UTC' do

      assert EtOrbi::EoTime.new(1193898300, 'Z').utc?
      assert EtOrbi::EoTime.new(1193898300, 'UTC').utc?
      assert EtOrbi::EoTime.new(1193898300, 'GMT').utc?
      assert EtOrbi::EoTime.new(1193898300, 'Zulu').utc?
    end

    test 'returns false else' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')

      assert ot.utc?, false
    end
  end

  group '#add' do

    test 'adds seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot.add(111)

      assert ot.seconds, 1193898300 + 111
    end

    test 'adds anything that has a #to_i and is not a String, gh-40' do

      ot =
        EtOrbi::EoTime.new(1193898300, 'Asia/Vladivostok') +
        TestActiveSupportDuration.new(3600) # 1.hour

      assert ot.seconds, 1193898300 + 3600
    end

    test 'goes into DST' do

      ot =
        EtOrbi::EoTime.new(
          Time.gm(2015, 3, 8, 9, 59, 59),
          'America/Los_Angeles')

      t0 = ot.dup
      ot.add(1)
      t1 = ot

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t1.isdst}"

      assert t0.to_i, 1425808799
      assert t1.to_i, 1425808800
      assert st0, '2015/03/08 01:59:59 PST false'
      assert st1, '2015/03/08 03:00:00 PDT true'
    end

    test 'goes out of DST' do

      ot = EtOrbi.parse('2014-10-26 01:59:59 Europe/Berlin')
        #
        # still in DST, DST ends (clock backward) at 03:00
        # https://www.timeanddate.com/time/change/germany/berlin

      t0 = ot.dup
      ot.add(1)
      t1 = ot.dup
      ot.add(3600)
      t2 = ot.dup
      ot.add(1)
      t3 = ot

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t1.isdst}"
      st2 = t2.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t2.isdst}"
      st3 = t3.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t3.isdst}"

      assert t0.to_i, 1414281599
      assert t1.to_i, 1414285200 - 3600
      assert t2.to_i, 1414285200
      assert t3.to_i, 1414285201

      assert st0, '2014/10/26 01:59:59 CEST true'
      assert st1, '2014/10/26 02:00:00 CEST true'
      assert st2, '2014/10/26 02:00:00 CET false'
      assert st3, '2014/10/26 02:00:01 CET false'

      assert t1 - t0, 1
      assert t2 - t1, 3600
      assert t3 - t2, 1
    end

    test 'returns self' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = ot.subtract(111)

      assert ot1.object_id, ot.object_id
    end
  end

  group '#subtract' do

    test 'substracts seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot.subtract(111)

      assert ot.seconds, 1193898300 - 111
    end

    test 'subtracts anything that has a #to_i and is not a String, gh-40' do

      ot =
        EtOrbi::EoTime.new(1193898300, 'Asia/Vladivostok') -
        TestActiveSupportDuration.new(3600) # 1.hour

      assert ot.seconds, 1193898300 - 3600
    end

    test 'returns self' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = ot.subtract(111)

      assert ot1.object_id, ot.object_id
    end
  end

  group '#to_f' do

    test 'returns the @seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')

      assert ot.to_f, 1193898300
    end
  end

  group '#to_s' do

    test 'returns the a formatted datetime string' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')

      assert ot.to_s, '2007-11-01 07:25:00 +0100'
    end
  end

  group '#to_zs' do

    test 'returns the a formatted datetime string with an explicit timezone' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')

      assert ot.to_zs, '2007-11-01 07:25:00 Europe/Paris'
    end
  end

  group '#strftime' do

    test 'accepts %Z, %z, %:z and %::z' do

      assert(
        EtOrbi::EoTime.new(0, 'Europe/Bratislava') \
          .strftime('%Y-%m-%d %H:%M:%S %Z %z %:z %::z'),
        '1970-01-01 01:00:00 CET +0100 +01:00 +01:00:00')
    end

    test 'accepts %/Z' do

      assert(
        EtOrbi::EoTime.new(0, 'Europe/Bratislava') \
          .strftime('%Y-%m-%d %H:%M:%S %/Z'),
        "1970-01-01 01:00:00 Europe/Bratislava")
    end
  end

  group '#monthdays' do

    [
      [ [ 1970, 1, 1 ], %w[ 4#1 4#-5 ] ],
      [ [ 1970, 1, 7 ], %w[ 3#1 3#-4 ] ],
      [ [ 1970, 1, 14 ], %w[ 3#2 3#-3 ] ],
      [ [ 2011, 3, 11 ], %w[ 5#2 5#-3 ] ]
    ].each do |d, x|

      test "returns the #{x.inspect} for #{d.inspect}" do

        t = EtOrbi.parse("#{d.join('-')} 12:00")

        assert t.monthdays, x
      end
    end
  end

  group '#+' do

    test 'adds seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = ot + 111

      assert ot1.class, EtOrbi::EoTime
      assert ot1.seconds, 1193898300 + 111
      assert ot1.object_id != ot.object_id
    end

    test 'rejects Time instances' do

      ot =
        EtOrbi.make_time('2017-10-31 22:00:10 Europe/Paris')
      t =
        in_zone('America/Los_Angeles') { Time.local(2017, 10, 30, 22, 00, 10) }

      assert_error(
        lambda { ot + t },
        ArgumentError, 'Cannot add Time to EoTime instance')
    end

    test 'rejects EoTime instances' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')

      assert_error(
        lambda { ot + ot1 },
        ArgumentError, 'Cannot add EtOrbi::EoTime to EoTime instance')
    end
  end

  group '#-' do

    test 'subtracts seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = ot - 111

      assert ot1.class, EtOrbi::EoTime
      assert ot1.seconds, 1193898300 - 111
      assert ot1.object_id != ot.object_id
    end

    test 'subtracts Time instances' do

      ot = EtOrbi.make_time('2017-10-31 22:00:10 Europe/Paris')

      #t = time_in_zone('America/Los_Angeles', '2017-10-30 22:00:10')
#time_in_zone('PST7PDT', '2017-10-30 22:00:10')
      t = Time.parse('2017-10-30 22:00:10 -0700')
        # because of https://ci.appveyor.com/project/jmettraux/et-orbi/build/job/evp6dmqegfgxhcnm

      d = ot - t

      assert d.class, Float
      assert d.to_i, 57600
    end

    test 'subtracts EoTime instances' do

      ot0 = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = EtOrbi::EoTime.new(1193898300 + 222, 'America/Los_Angeles')
      d = ot0 - ot1

      assert d.class, Float
      assert d.to_i, -222
    end
  end

  group '#wday_in_month' do

    {

      [ 1193898300, 'Europe/Paris' ] => [ 1, -5 ],
      '2017-06-21 Europe/Paris' => [ 3, -2 ],
      '2022-03-29 UTC' => [ 5, -1 ],
      '2022-03-29 Europe/Paris' => [ 5, -1 ],

    }.each do |k, v|

      test "computes the wday in month interval for #{k.inspect}" do

        t =
          case k
          when String then EtOrbi.make_time(k)
          else EtOrbi::EoTime.new(*k)
          end

        assert t.wday_in_month, v
      end
    end
  end

  WDAYS = %w[ sun mon tue wed thu fri sat sun ]

  group '#rweek, #rday' do

    {

      '2008-12-31 12:00 Europe/Lisbon' => [ 'wed', 366, -521, -3652 ],
      '2018-12-31 12:00 Europe/London' => [ 'mon', 365, 0, 0 ],
      '2019-01-01 12:00 Europe/Paris' => [ 'tue', 1, 1, 1 ],
      '2019-04-02 12:00 Europe/Berlin' => [ 'tue', 92, 13, 91 ],
      '2020-01-01 America/Sao_Paulo' => [ 'wed', 1, 53, 366 ],
      '2020-01-01 America/Santarem' => [ 'wed', 1, 53, 366 ],

      # https://github.com/floraison/fugit/issues/96
      #
      '2024-03-12 12:59:59 Etc/UTC' => [ 'tue', 72, 272, 1898 ],
      '2024-03-12 11:59:59 Etc/UTC' => [ 'tue', 72, 272, 1898 ],

    }.each do |t, (wday, yday, rweek, rday)|

      test "for #{t}, returns rweek:#{rweek}/rday:#{rday}" do

        t = EtOrbi.make_time(t)

        assert(
          [ WDAYS[t.wday], t.yday, t.rweek, t.rday ],
          [ wday, yday, rweek, rday ])
      end
    end
  end

  group '#localtime' do

    test 'returns a new EoTime instance in the local zone' do

      t = EtOrbi::EoTime.new(1193898300, 'Pacific/Apia')

      assert t.to_s, '2007-10-31 19:25:00 -1100'

      t1 = in_zone('Europe/Moscow') { t.localtime }

      assert t1.to_s, '2007-11-01 09:25:00 +0300'
      assert t1.object_id != t.object_id
    end
  end

  group '#localtime(zone)' do

    test 'returns a new EoTime instance local to a given zone' do

      t = EtOrbi::EoTime.new(1193898300, 'Pacific/Apia')

      assert t.to_s, '2007-10-31 19:25:00 -1100'

      t1 = t.localtime('Europe/Paris')

      assert t1.to_s, '2007-11-01 07:25:00 +0100'
      assert t1.object_id != t.object_id
    end

    test 'returns a new EoTime instance event if target zone is the same' do

      t = EtOrbi::EoTime.new(1193898300, 'Pacific/Apia')

      assert t.to_s, '2007-10-31 19:25:00 -1100'

      t1 = t.localtime('Pacific/Apia')

      assert t1.to_s, '2007-10-31 19:25:00 -1100'
      assert t1.object_id != t.object_id
    end
  end

  group '#translate(zone=nil)' do

    test 'is an alias to #localtime(zone=nil)' do

      t = EtOrbi::EoTime.new(1193898300, 'Pacific/Apia')

      assert t.to_s, '2007-10-31 19:25:00 -1100'

      t1 = t.translate('Europe/Paris')

      assert t1.to_s, '2007-11-01 07:25:00 +0100'
      assert t1.object_id != t.object_id
    end
  end

  group '#in_time_zone(zone=nil)' do

    test 'is an alias to #localtime(zone=nil)' do

      t = EtOrbi::EoTime.new(1193898300, 'Pacific/Apia')

      assert t.to_s, '2007-10-31 19:25:00 -1100'

      t1 = t.in_time_zone('Europe/Moscow')

      assert t1.to_s, '2007-11-01 09:25:00 +0300'
      assert t1.object_id != t.object_id
    end
  end

  group '#iso8601' do

    [

      [ 1193898300, 'Pacific/Apia', nil, '2007-10-31T19:25:00-11:00' ],
      [ 1193898300, 'UTC', nil, '2007-11-01T06:25:00Z' ],
      [ '2017-06-21 Europe/Paris', nil, nil, '2017-06-21T00:00:00+02:00' ],
      [ '2017-01-21 Europe/Paris', nil, nil, '2017-01-21T00:00:00+01:00' ],

      #[ 1193898300.11, 'Pacific/Apia', 2, '2007-10-31T19:25:00.10-11:00' ],#???
      [ 1193898300.70, 'UTC', 1, '2007-11-01T06:25:00.7Z' ],
      [ '2017-06-21 Europe/Paris', nil, 2, '2017-06-21T00:00:00.00+02:00' ],
      [ '2017-01-21 Europe/Paris', nil, 3, '2017-01-21T00:00:00.000+01:00' ],

    ].each do |s, z, f, i|

      test "returns #{i.inspect}" do

        t =
          if z
            EtOrbi::EoTime.new(s, z)
          else
            EtOrbi.make_time(s)
          end

        assert t.iso8601(f), i
      end
    end
  end

  group '#ambiguous?' do

    # https://www.timeanddate.com/time/change/usa/new-york?year=2018

    test 'returns false if test has a unique corresponding UTC time' do

      # whatever the local zone!

      t = EtOrbi::EoTime.new(
        EtOrbi.parse('2018-11-04 00:00:00 -0400').to_f,
        'America/New_York')

      assert t.ambiguous?, false
    end

    test 'returns true if test has two corresponding UTC times (DST to non-DST)' do

      # whatever the local zone!

      t = EtOrbi::EoTime.new(
        EtOrbi.parse('2018-11-04 01:30:00 -0400').to_f,
        'America/New_York')

      assert t.ambiguous?, true
    end
  end

  group '#reach' do

    {

      [ '2018-07-24 01:31:00 America/New_York', { min: 30 } ] =>
        '2018-07-24 02:30:00 America/New_York',
      [ '2018-07-24 01:31:00 America/New_York', { hou: 7 } ] =>
        '2018-07-24 07:00:00 America/New_York',
      [ '2018-07-24 01:31:00 America/New_York', { hou: 7, min: 25 } ] =>
        '2018-07-24 07:25:00 America/New_York',
      [ '2018-07-24 01:31:00 America/New_York', { h: 7, m: 25, s: 10 } ] =>
        '2018-07-24 07:25:10 America/New_York',
      [ '2018-07-24 01:31:00 America/New_York', { h: 7, s: 10 } ] =>
        '2018-07-24 07:00:10 America/New_York',

    }.each do |(start, points), result|

      test "reaches for #{points.inspect}" do

        t = EtOrbi.parse(start)
        t = t.reach(points)

        assert t.to_zs, result
      end
    end
  end

  group '#==' do

    group 'EoTime == EoTime' do

      test 'returns true if same s and same TZ' do

        eo0 = EtOrbi.parse('2018-11-04 01:30:00 -0400')
        eo1 = EtOrbi.parse('2018-11-04 01:30:00 -0400')

        assert eo0 == eo1
      end

      test 'returns false if not in the same timezone' do

        eo0 = EtOrbi.parse('2018-11-04 02:30:00 Europe/Berlin')
        eo1 = EtOrbi.parse('2018-11-04 01:30:00 Europe/London')

        assert eo0.to_i == eo1.to_i
        assert eo0 == eo1, false
      end
    end

    group 'EoTime == Time' do

      test 'returns true when same sec' do

        eo = EtOrbi.parse('2018-11-04 02:30:00 Europe/Berlin')
        t = Time.at(eo.to_i)

        assert eo == t
        assert eo, t
      end

      test 'returns false else' do

        eo = EtOrbi.parse('2018-11-04 02:30:00 Europe/Berlin')
        t = Time.at(eo.to_i + 1)

        assert eo == t, false
        assert eo != t
      end
    end

    group 'Time == EoTime' do # ehm, yeah, testing Ruby somehow...

      test 'returns true when same sec' do

        eo = EtOrbi.parse('2018-11-04 02:30:00 Europe/Berlin')
        t = Time.at(eo.to_i)

        assert t == eo, true # thanks Ruby!
        assert t, eo
      end

      test 'returns false else' do

        eo = EtOrbi.parse('2018-11-04 02:30:00 Europe/Berlin')
        t = Time.at(eo.to_i + 1)

        assert t == eo, false
        assert t != eo
      end
    end
  end

  group '#<, #<=, #>, #>=, #<=>' do

    [

      [ EtOrbi.parse('2018-11-04 02:30:00 Europe/Berlin'),
        :>,
        EtOrbi.parse('2018-11-04 02:00:00 Europe/Berlin'),
        true ],
      [ EtOrbi.parse('2018-11-04 02:00:00 Europe/Berlin'),
        :>,
        EtOrbi.parse('2018-11-04 02:30:00 Europe/Berlin'),
        false ],
      [ EtOrbi.parse('2018-11-04 02:00:00 Europe/London'),
        :>,
        EtOrbi.parse('2018-11-04 02:00:00 Europe/Berlin'),
        true ],
      [ EtOrbi.parse('2018-11-04 02:00:00 Europe/Berlin'),
        :>,
        EtOrbi.parse('2018-11-04 02:00:00 Europe/London'),
        false ],
      [ EtOrbi.parse('2018-11-04 02:00:00 Europe/London'),
        :>,
        Time.at(EtOrbi.parse('2018-11-04 02:00:00 Europe/Berlin').to_i),
        true ],
      [ EtOrbi.parse('2018-11-04 02:00:00 Europe/Berlin'),
        :>,
        Time.at(EtOrbi.parse('2018-11-04 02:00:00 Europe/Berlin').to_i),
        false ],

    ].each do |t0, comparator, t1, asserted|

      to_s = lambda { |o|
        case o
        when EtOrbi::EoTime then "#{o.to_s} (EoTime)"
        else "#{o.to_s} (#{o.class})"
        end }

      s0 = to_s[t0]
      s1 = to_s[t1]

      test "#{s0} #{comparator.to_s} #{s1} yields #{asserted.inspect}" do

        assert t0.send(comparator, t1), asserted
      end
    end
  end
end

