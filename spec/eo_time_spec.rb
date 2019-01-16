# encoding: UTF-8

#
# Specifying EtOrbi
#
# Wed Mar 11 21:17:36 JST 2015, quatre ans... (rufus-scheduler)
# Sun Mar 19 05:16:28 JST 2017
#

require 'spec_helper'


describe EtOrbi::EoTime do

  describe '.new' do

    context "zone 'America/Los_Angeles'" do

      it 'accepts an integer' do

        ot = EtOrbi::EoTime.new(1234567890, 'America/Los_Angeles')

        expect(ot.seconds.to_i).to eq(1234567890)
        expect(ot.zone.name).to eq('America/Los_Angeles')
      end

      it 'accepts a float' do

        ot = EtOrbi::EoTime.new(1234567890.1234, 'America/Los_Angeles')

        expect(ot.seconds.to_i).to eq(1234567890)
        expect(ot.zone.name).to eq('America/Los_Angeles')
      end

      it 'accepts a UTC ::Time instance' do

        ot =
          EtOrbi::EoTime.new(
            Time.utc(2007, 11, 1, 15, 25, 0),
            'America/Los_Angeles')

        expect(ot.seconds.to_i).to eq(1193930700)
        expect(ot.zone.name).to eq('America/Los_Angeles')
      end

      it 'accepts a UTC EtOrbi::EoTime instance' do

        ot =
          EtOrbi::EoTime.new(
            EtOrbi::EoTime.new(1193930700, 'UTC'),
            'America/Los_Angeles')

        expect(ot.seconds.to_i).to eq(1193930700)
        expect(ot.zone.name).to eq('America/Los_Angeles')
      end

      it 'accepts a local ::Time instance' do

        #in_zone 'Asia/Samarkand' do
        #
        #  t = Time.parse('2007-11-01 15:25')
        #  ot = EtOrbi::EoTime.new(t, 'America/Los_Angeles')
        #
        #  expect(ot.seconds).to eq(t.to_i)
        #  expect(ot.seconds.to_i).to eq(1193912700)
        #  expect(ot.zone.name).to eq('America/Los_Angeles')
        #end
          #
          # because of https://ci.appveyor.com/project/jmettraux/et-orbi/build/job/8birnr0k54jrihx8

        t = Time.parse('2007-11-01 15:25 +05:00')
          # use a local ::Time instance with a custom timezone :-(

        ot = EtOrbi::EoTime.new(t, 'America/Los_Angeles')

        expect(ot.seconds).to eq(t.to_i)
        expect(ot.seconds.to_i).to eq(1193912700)
        expect(ot.zone.name).to eq('America/Los_Angeles')
      end

      it 'accepts a Local EtOrbi::EoTime instance' do

        ot =
          EtOrbi::EoTime.new(
            EtOrbi::EoTime.new(1193930700, 'Asia/Yekaterinburg'),
            'America/Los_Angeles')

        expect(ot.seconds.to_i).to eq(1193930700)
        expect(ot.zone.name).to eq('America/Los_Angeles')
      end
    end

    context "zone TZInfo instance 'Europe/Paris'" do

      it 'accepts an integer' do

        ot = EtOrbi::EoTime
          .new(1234567890, ::TZInfo::Timezone.get('Europe/Paris'))

        expect(ot.seconds.to_i).to eq(1234567890)
        expect(ot.zone.name).to eq('Europe/Paris')
      end
    end

    context "zone ActiveSupport::TimeZone instance 'America/New_York'" do

      it 'accepts an integer' do

        ot = EtOrbi::EoTime
          .new(1234567890, SpecActiveSupportTimeZone.make('America/New_York'))

        expect(ot.seconds.to_i).to eq(1234567890)
        expect(ot.zone.name).to eq('America/New_York')
      end
    end
  end

  describe '.utc' do

    [

      [ [ 2017, 3, 25 ], '2017-03-25T00:00:00Z' ],
      [ [ 2017, 3, 25, 21, 23, 29 ], '2017-03-25T21:23:29Z' ],

    ].each do |a, s|

      it "accepts #{a.inspect}" do

        ot = EtOrbi::EoTime.utc(*a)

        expect(ot.class).to eq(EtOrbi::EoTime)
        expect(ot.zone.name).to eq('UTC')
        expect(ot.iso8601).to eq(s)
      end
    end
  end

  describe '.local' do

    [

      [ [ 2017, 3, 25 ],
        %w[ Europe/Lisbon windows:WET ],
        '2017-03-25T00:00:00+00:00' ],
      [ [ 2017, 3, 25, 21, 23, 29 ],
        %w[ Europe/Lisbon windows:WET ],
        '2017-03-25T21:23:29+00:00' ],
      [ [ 2017, 3, 25, 21, 23, 29 ],
        %w[ Europe/Moscow ],
        '2017-03-25T21:23:29+03:00' ],

    ].each do |a, zs, s|

      it "accepts #{a.inspect} in #{zs.first}" do

        in_zone(zs.first) do

          ot = EtOrbi::EoTime.local(*a)

          expect(ot.class).to eq(EtOrbi::EoTime)
          expect(ot.zone).to be_one_of(select_zones(zs))
          expect(ot.iso8601).to eq(s)
        end
      end
    end
  end

  describe '#to_time (protected)' do

    if TZInfo::Timezone
       .get('America/Los_Angeles')
       .utc_to_local(Time.at(1193898300))
       .utc?
    then
      # TZInfo < 2.0.0

      it 'returns a local Time instance, although with a UTC zone' do

        ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
        t = ot.send(:to_time)

        expect(ot.to_debug_s).to eq('ot 2007-10-31 23:25:00 -07:00 dst:true')

        expect(t.to_i).to eq(1193898300 - 7 * 3600) # /!\
        expect(t.utc_offset).to eq(0)

        expect(t.to_debug_s).to eq('t 2007-10-31 23:25:00 +00:00 dst:false')
          # Time instance stuck to UTC...
      end

    else
      # TZInfo >= 2.0.0

      it 'returns a local Time instance' do

        ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
        t = ot.send(:to_time)

        expect(ot.to_debug_s).to eq('ot 2007-10-31 23:25:00 -07:00 dst:true')

        expect(t.to_i).to eq(1193898300)
        expect(t.utc_offset).to eq(-7 * 3600)

        expect(t.to_debug_s).to eq('t 2007-10-31 23:25:00 -07:00 dst:true')
      end
    end
  end

  describe '#to_local_time' do

    it 'returns a local Time instance in the local time zone' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      t = ot.to_local_time

      expect(t.class).to eq(::Time)
      expect(t.to_i).to eq(1193898300)
      expect(t.usec).to eq(0)

      t1 = Time.parse(t.strftime("%Y-%m-%d %H:%M:%S.#{'%06d' % t.usec}"))
      expect(t.to_s).to eq(t1.to_s)
    end
  end

  describe '#to_t' do

    it 'is an alias to #to_local_time' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      t = ot.to_t

      expect(t.class).to eq(::Time)
      expect(t.to_i).to eq(1193898300)
      expect(t.usec).to eq(0)
    end
  end

  describe '#to_utc_time' do

    it 'is an alias to #to_utc' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      ut = ot.to_utc_time

      expect(ut.class).to eq(::Time)
      expect(ut.to_i).to eq(1193898300)
      expect(ut.usec).to eq(0)

      expect(ut.to_s).to eq('2007-11-01 06:25:00 UTC')
    end
  end

  describe '#utc' do

    it 'returns an UTC Time instance' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      ut = ot.utc

      expect(ut.to_i).to eq(1193898300)

      expect(ot.to_debug_s).to eq('ot 2007-10-31 23:25:00 -07:00 dst:true')
      expect(ut.to_debug_s).to eq('t 2007-11-01 06:25:00 +00:00 dst:false')
    end
  end

  describe '#utc?' do

    it 'returns true if the EoTime zone is UTC' do

      expect(EtOrbi::EoTime.new(1193898300, 'Z').utc?).to eq(true)
      expect(EtOrbi::EoTime.new(1193898300, 'UTC').utc?).to eq(true)
      expect(EtOrbi::EoTime.new(1193898300, 'GMT').utc?).to eq(true)
      expect(EtOrbi::EoTime.new(1193898300, 'Zulu').utc?).to eq(true)
    end

    it 'returns false else' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')

      expect(ot.utc?).to eq(false)
    end
  end

  describe '#add' do

    it 'adds seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot.add(111)

      expect(ot.seconds).to eq(1193898300 + 111)
    end

    it 'goes into DST' do

      ot =
        EtOrbi::EoTime.new(
          Time.gm(2015, 3, 8, 9, 59, 59),
          'America/Los_Angeles')

      t0 = ot.dup
      ot.add(1)
      t1 = ot

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t1.isdst}"

      expect(t0.to_i).to eq(1425808799)
      expect(t1.to_i).to eq(1425808800)
      expect(st0).to eq('2015/03/08 01:59:59 PST false')
      expect(st1).to eq('2015/03/08 03:00:00 PDT true')
    end

    it 'goes out of DST' do

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

      expect(t0.to_i).to eq(1414281599)
      expect(t1.to_i).to eq(1414285200 - 3600)
      expect(t2.to_i).to eq(1414285200)
      expect(t3.to_i).to eq(1414285201)

      expect(st0).to eq('2014/10/26 01:59:59 CEST true')
      expect(st1).to eq('2014/10/26 02:00:00 CEST true')
      expect(st2).to eq('2014/10/26 02:00:00 CET false')
      expect(st3).to eq('2014/10/26 02:00:01 CET false')

      expect(t1 - t0).to eq(1)
      expect(t2 - t1).to eq(3600)
      expect(t3 - t2).to eq(1)
    end

    it 'returns self' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = ot.subtract(111)

      expect(ot1.object_id).to eq(ot.object_id)
    end
  end

  describe '#subtract' do

    it 'substracts seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot.subtract(111)

      expect(ot.seconds).to eq(1193898300 - 111)
    end

    it 'returns self' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = ot.subtract(111)

      expect(ot1.object_id).to eq(ot.object_id)
    end
  end

  describe '#to_f' do

    it 'returns the @seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')

      expect(ot.to_f).to eq(1193898300)
    end
  end

  describe '#to_s' do

    it 'returns the a formatted datetime string' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')

      expect(ot.to_s).to eq('2007-11-01 07:25:00 +0100')
    end
  end

  describe '#to_zs' do

    it 'returns the a formatted datetime string with an explicit timezone' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')

      expect(ot.to_zs).to eq('2007-11-01 07:25:00 Europe/Paris')
    end
  end

  describe '#strftime' do

    it 'accepts %Z, %z, %:z and %::z' do

      expect(
        EtOrbi::EoTime.new(0, 'Europe/Bratislava') \
          .strftime('%Y-%m-%d %H:%M:%S %Z %z %:z %::z')
      ).to eq(
        '1970-01-01 01:00:00 CET +0100 +01:00 +01:00:00'
      )
    end

    it 'accepts %/Z' do

      expect(
        EtOrbi::EoTime.new(0, 'Europe/Bratislava') \
          .strftime('%Y-%m-%d %H:%M:%S %/Z')
      ).to eq(
        "1970-01-01 01:00:00 Europe/Bratislava"
      )
    end
  end

  describe '#monthdays' do

    [
      [ [ 1970, 1, 1 ], %w[ 4#1 4#-5 ] ],
      [ [ 1970, 1, 7 ], %w[ 3#1 3#-4 ] ],
      [ [ 1970, 1, 14 ], %w[ 3#2 3#-3 ] ],
      [ [ 2011, 3, 11 ], %w[ 5#2 5#-3 ] ]
    ].each do |d, x|

      it "returns the #{x.inspect} for #{d.inspect}" do

        t = EtOrbi.parse("#{d.join('-')} 12:00")

        expect(t.monthdays).to eq(x)
      end
    end
  end

  describe '#+' do

    it 'adds seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = ot + 111

      expect(ot1.class).to eq(EtOrbi::EoTime)
      expect(ot1.seconds).to eq(1193898300 + 111)
      expect(ot1.object_id).not_to eq(ot.object_id)
    end

    it 'rejects Time instances' do

      ot =
        EtOrbi.make_time('2017-10-31 22:00:10 Europe/Paris')
      t =
        in_zone('America/Los_Angeles') { Time.local(2017, 10, 30, 22, 00, 10) }

      expect {
        ot + t
      }.to raise_error(
        ArgumentError, 'Cannot add Time to EoTime'
      )
    end

    it 'rejects EoTime instances' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')

      expect {
        ot + ot1
      }.to raise_error(
        ArgumentError, 'Cannot add EtOrbi::EoTime to EoTime'
      )
    end
  end

  describe '#-' do

    it 'subtracts seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = ot - 111

      expect(ot1.class).to eq(EtOrbi::EoTime)
      expect(ot1.seconds).to eq(1193898300 - 111)
      expect(ot1.object_id).not_to eq(ot.object_id)
    end

    it 'subtracts Time instances' do

      ot = EtOrbi.make_time('2017-10-31 22:00:10 Europe/Paris')

      #t = time_in_zone('America/Los_Angeles', '2017-10-30 22:00:10')
#time_in_zone('PST7PDT', '2017-10-30 22:00:10')
      t = Time.parse('2017-10-30 22:00:10 -0700')
        # because of https://ci.appveyor.com/project/jmettraux/et-orbi/build/job/evp6dmqegfgxhcnm

      d = ot - t

      expect(d.class).to eq(Float)
      expect(d.to_i).to eq(57600)
    end

    it 'subtracts EoTime instances' do

      ot0 = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = EtOrbi::EoTime.new(1193898300 + 222, 'America/Los_Angeles')
      d = ot0 - ot1

      expect(d.class).to eq(Float)
      expect(d.to_i).to eq(-222)
    end
  end

  describe '#wday_in_month' do

    it 'computes the wday in month interval' do

      t = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')

      expect(t.wday_in_month).to eq([ 1, -5 ])

      t = EtOrbi.make_time('2017-06-21 Europe/Paris')

      expect(t.wday_in_month).to eq([ 3, -2 ])
    end
  end

  describe '#localtime' do

    it 'returns a new EoTime instance in the local zone' do

      t = EtOrbi::EoTime.new(1193898300, 'Pacific/Apia')

      expect(t.to_s).to eq('2007-10-31 19:25:00 -1100')

      t1 = in_zone('Europe/Moscow') { t.localtime }

      expect(t1.to_s).to eq('2007-11-01 09:25:00 +0300')
      expect(t1.object_id).not_to eq(t.object_id)
    end
  end

  describe '#localtime(zone)' do

    it 'returns a new EoTime instance local to a given zone' do

      t = EtOrbi::EoTime.new(1193898300, 'Pacific/Apia')

      expect(t.to_s).to eq('2007-10-31 19:25:00 -1100')

      t1 = t.localtime('Europe/Paris')

      expect(t1.to_s).to eq('2007-11-01 07:25:00 +0100')
      expect(t1.object_id).not_to eq(t.object_id)
    end

    it 'returns a new EoTime instance event if target zone is the same' do

      t = EtOrbi::EoTime.new(1193898300, 'Pacific/Apia')

      expect(t.to_s).to eq('2007-10-31 19:25:00 -1100')

      t1 = t.localtime('Pacific/Apia')

      expect(t1.to_s).to eq('2007-10-31 19:25:00 -1100')
      expect(t1.object_id).not_to eq(t.object_id)
    end
  end

  describe '#translate(zone=nil)' do

    it 'is an alias to #localtime(zone=nil)' do

      t = EtOrbi::EoTime.new(1193898300, 'Pacific/Apia')

      expect(t.to_s).to eq('2007-10-31 19:25:00 -1100')

      t1 = t.translate('Europe/Paris')

      expect(t1.to_s).to eq('2007-11-01 07:25:00 +0100')
      expect(t1.object_id).not_to eq(t.object_id)
    end
  end

  describe '#in_time_zone(zone=nil)' do

    it 'is an alias to #localtime(zone=nil)' do

      t = EtOrbi::EoTime.new(1193898300, 'Pacific/Apia')

      expect(t.to_s).to eq('2007-10-31 19:25:00 -1100')

      t1 = t.in_time_zone('Europe/Moscow')

      expect(t1.to_s).to eq('2007-11-01 09:25:00 +0300')
      expect(t1.object_id).not_to eq(t.object_id)
    end
  end

  describe '#iso8601' do

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

      it "returns #{i.inspect}" do

        t =
          if z
            EtOrbi::EoTime.new(s, z)
          else
            EtOrbi.make_time(s)
          end

        expect(t.iso8601(f)).to eq(i)
      end
    end
  end

  describe '#ambiguous?' do

    # https://www.timeanddate.com/time/change/usa/new-york?year=2018

    it 'returns false if it has a unique corresponding UTC time' do

      # whatever the local zone!

      t = EtOrbi::EoTime.new(
        EtOrbi.parse('2018-11-04 00:00:00 -0400').to_f,
        'America/New_York')

      expect(t.ambiguous?).to eq(false)
    end

    it 'returns true if it has two corresponding UTC times (DST to non-DST)' do

      # whatever the local zone!

      t = EtOrbi::EoTime.new(
        EtOrbi.parse('2018-11-04 01:30:00 -0400').to_f,
        'America/New_York')

      expect(t.ambiguous?).to eq(true)
    end
  end

  describe '#reach' do

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

      it "reaches for #{points.inspect}" do

        t = EtOrbi.parse(start)
        t = t.reach(points)

        expect(t.to_zs).to eq(result)
      end
    end
  end
end

