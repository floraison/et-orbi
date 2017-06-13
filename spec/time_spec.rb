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

    it 'accepts an integer' do

      ot = EtOrbi::EoTime.new(1234567890, 'America/Los_Angeles')

      expect(ot.seconds.to_i).to eq(1234567890)
    end

    it 'accepts a float' do

      ot = EtOrbi::EoTime.new(1234567890.1234, 'America/Los_Angeles')

      expect(ot.seconds.to_i).to eq(1234567890)
    end

    it 'accepts a Time instance' do

      ot =
        EtOrbi::EoTime.new(
          Time.utc(2007, 11, 1, 15, 25, 0),
          'America/Los_Angeles')

      expect(ot.seconds.to_i).to eq(1193930700)
    end
  end

  describe '#to_time' do

    it 'returns a local Time instance, although with a UTC zone' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      t = ot.to_time

      expect(ot.to_debug_s).to eq('ot 2007-10-31 23:25:00 -08:00 dst:true')

      expect(t.to_i).to eq(1193898300 - 7 * 3600) # /!\

      expect(t.to_debug_s).to eq('t 2007-10-31 23:25:00 +00:00 dst:false')
        # Time instance stuck to UTC...
    end
  end

  describe '#utc' do

    it 'returns an UTC Time instance' do

      ot = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      ut = ot.utc

      expect(ut.to_i).to eq(1193898300)

      expect(ot.to_debug_s).to eq('ot 2007-10-31 23:25:00 -08:00 dst:true')
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

      ot =
        EtOrbi::EoTime.new(
          ltz('Europe/Berlin', 2014, 10, 26, 01, 59, 59),
          'Europe/Berlin')

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

    def mds(t); EtOrbi::EoTime.new(t.to_f, nil).monthdays; end

    it 'returns the appropriate "0#2"-like string' do

      expect(mds(local(1970, 1, 1))).to eq(%w[ 4#1 4#-5 ])
      expect(mds(local(1970, 1, 7))).to eq(%w[ 3#1 3#-4 ])
      expect(mds(local(1970, 1, 14))).to eq(%w[ 3#2 3#-3 ])

      expect(mds(local(2011, 3, 11))).to eq(%w[ 5#2 5#-3 ])
    end
  end

  describe '#+' do

    it 'adds seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = ot + 111

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
        ArgumentError, 'cannot add Time to EoTime'
      )
    end

    it 'rejects EoTime instances' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')

      expect {
        ot + ot1
      }.to raise_error(
        ArgumentError, 'cannot add EtOrbi::EoTime to EoTime'
      )
    end
  end

  describe '#-' do

    it 'subtracts seconds' do

      ot = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = ot - 111

      expect(ot1.seconds).to eq(1193898300 - 111)
      expect(ot1.object_id).not_to eq(ot.object_id)
    end

    it 'subtracts Time instances' do

      ot =
        EtOrbi.make_time('2017-10-31 22:00:10 Europe/Paris')
      t =
        in_zone('America/Los_Angeles') { Time.local(2017, 10, 30, 22, 00, 10) }

      r = ot - t

      expect(r.to_i).to eq(57600)
    end

    it 'subtracts EoTime instances' do

      ot0 = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      ot1 = EtOrbi::EoTime.new(1193898300 + 222, 'America/Los_Angeles')

      expect((ot0 - ot1).to_i).to eq(-222)
    end
  end
end

