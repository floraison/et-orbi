# encoding: UTF-8

#
# Specifying EtOrbi
#
# Wed Mar 11 21:17:36 JST 2015, quatre ans... (rufus-scheduler)
# Sun Mar 19 05:16:28 JST 2017
# Fri Mar 24 04:55:25 JST 2017 圓さんの家
#

require 'spec_helper'


describe EtOrbi do

  describe '.list_iso8601_zones' do

    def liz(s); EtOrbi.list_iso8601_zones(s); end

    it 'returns the zone string' do

      expect(liz '2016-11-01 12:30:09-01').to eq(%w[ -01 ])
      expect(liz '2016-11-01 12:30:09-01:00').to eq(%w[ -01:00 ])
      expect(liz '2016-11-01 12:30:09 -01').to eq(%w[ -01 ])
      expect(liz '2016-11-01 12:30:09 -01:00').to eq(%w[ -01:00 ])

      expect(liz '2016-11-01 12:30:09-01:30').to eq(%w[ -01:30 ])
      expect(liz '2016-11-01 12:30:09 -01:30').to eq(%w[ -01:30 ])
    end

    it 'returns nil when it cannot find a zone' do

      expect(liz '2016-11-01 12:30:09').to eq([])
      expect(liz '2016-11-01 12:30:09-25').to eq([])
      expect(liz '2016-11-01 12:30:09-25:00').to eq([])
    end
  end

  describe '.list_olson_zones' do

    def loz(s); EtOrbi.list_olson_zones(s); end

    it 'returns the zone strings' do

      expect(
        loz '11/09/2002 America/New_York'
      ).to eq(%w[
        America/New_York
      ])
      expect(
        loz '11/09/2002 America/New_York Asia/Shanghai'
      ).to eq(%w[
        America/New_York Asia/Shanghai
      ])
      expect(
        loz 'America/New_York Asia/Shanghai'
      ).to eq(%w[
        America/New_York Asia/Shanghai
      ])
    end

    it 'returns [] when it cannot find a zone' do

      expect(
        loz '11/09/2002 2utopiaNada?3Nada'
      ).to eq(%w[
      ])
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
        ArgumentError, 'no time information in "xxx"'
      )
    end
  end

  describe '.get_tzone' do

    def gtz(s); z = EtOrbi.get_tzone(s); z ? z.name : z; end

    it 'returns a tzone for known zone strings' do

      expect(gtz('GB')).to eq('GB')
      expect(gtz('UTC')).to eq('UTC')
      expect(gtz('GMT')).to eq('GMT')
      expect(gtz('Zulu')).to eq('Zulu')
      expect(gtz('Japan')).to eq('Japan')
      expect(gtz('Turkey')).to eq('Turkey')
      expect(gtz('Asia/Tokyo')).to eq('Asia/Tokyo')
      expect(gtz('Europe/Paris')).to eq('Europe/Paris')
      expect(gtz('Europe/Zurich')).to eq('Europe/Zurich')
      expect(gtz('W-SU')).to eq('W-SU')

      expect(gtz('Z')).to eq('Zulu')

      expect(gtz('+09:00')).to eq('+09:00')
      expect(gtz('-01:30')).to eq('-01:30')

      expect(gtz('+08:00')).to eq('+08:00')
      expect(gtz('+0800')).to eq('+0800') # no normalization to "+08:00"

      expect(gtz('-01')).to eq('-01')

      expect(gtz(3600)).to eq('+01:00')
    end

#    it 'returns a timezone for well-known abbreviations' do
#
#      expect(gtz('JST')).to eq('Japan')
#      expect(gtz('PST')).to eq('America/Dawson')
#      expect(gtz('CEST')).to eq('Africa/Ceuta')
#    end

    it 'returns nil for unknown zone names' do

      expect(gtz('Asia/Paris')).to eq(nil)
      expect(gtz('Nada/Nada')).to eq(nil)
      expect(gtz('7')).to eq(nil)
      expect(gtz('06')).to eq(nil)
      expect(gtz('sun#3')).to eq(nil)
      expect(gtz('Mazda Zoom Zoom Stadium')).to eq(nil)
    end

    # rufus-scheduler gh-222
    it "falls back to ENV['TZ'] if it doesn't know Time.now.zone" do

      begin

        current = EtOrbi.get_tzone(:local)

        class ::Time
          alias _original_zone zone
          def zone; "中国标准时间"; end
        end

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

          expect(
            EtOrbi.get_tzone(:local)
          ).to eq(
            EtOrbi.get_tzone('Asia/Shanghai')
          )
        end

      ensure

        class ::Time
          def zone; _original_zone; end
        end
      end

      expect(
        EtOrbi.get_tzone(:local)
      ).to eq(
        current
      )
    end

    [ # for rufus-scheduler gh-228

      [ 'Asia/Tokyo', 'Asia/Tokyo' ],
      [ 'Asia/Shanghai', 'Asia/Shanghai' ],
      [ 'Europe/Zurich', 'Europe/Zurich' ],
      [ 'Europe/London', 'Europe/London' ]

    ].each do |zone, target|

      it "returns the current timezone for :current in #{zone}" do

        in_zone(zone) do

          expect(
            EtOrbi.get_tzone(:local)
          ).to eq(
            EtOrbi.get_tzone(target)
          )
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

      in_zone('Europe/Berlin') do

        expect(
          EtOrbi.determine_local_tzone.name
        ).to eq(
          'Europe/Berlin'
        )
      end
    end
  end

  describe '.local_tzone' do

    it 'caches and returns the local timezone' do

      in_zone('Europe/Berlin') do
        expect(EtOrbi.local_tzone.name).to eq('Europe/Berlin')
      end
      in_zone('America/Jamaica') do
        expect(EtOrbi.local_tzone.name).to eq('America/Jamaica')
      end
    end

    it 'returns the Rails tzone if available' do

      class ArZone
        def initialize(z); @z = z; end
        def tzinfo; @z; end
      end

      Time.class_eval do
        def self.zone
          ArZone.new(::TZInfo::Timezone.get('Europe/Vilnius'))
        end
      end

      in_zone(nil) do
        expect(EtOrbi.local_tzone.name).to eq('Europe/Vilnius')
      end
      in_zone('Asia/Tehran') do
        expect(EtOrbi.local_tzone.name).to eq('Asia/Tehran')
      end

      Time.class_eval do
        class << self
          undef zone
        end
      end
    end
  end

  describe '.now' do

    it 'returns a current, local EoTime instance' do

      in_zone 'Asia/Shanghai' do

        t = EtOrbi.now
        n = Time.now

        expect(t.seconds).to be_between((n - 1).to_f, (n + 1).to_f)
        expect(t.zone.name).to eq('Asia/Shanghai')
      end
    end
  end

  describe '.make_time' do

    it 'accepts a EtOrbi::EoTime' do

      expect(
        EtOrbi.make_time(
          EtOrbi.parse('2017-03-21 12:00:34 Asia/Ulan_Bator')
        ).to_debug_s
      ).to eq(
        'ot 2017-03-21 12:00:34 +08:00 dst:false'
      )
    end

    it 'accepts a local Time' do

      in_zone 'Asia/Tbilisi' do

        expect(
          EtOrbi.make_time(
            Time.local(2016, 11, 01, 12, 30, 9)
          ).to_debug_s
        ).to eq(
          'ot 2016-11-01 12:30:09 +04:00 dst:false'
        )
      end
    end

    it 'rejects a Time in a non-local ambiguous timezone' do

      t = Time.local(2016, 11, 01, 12, 30, 9)
      class << t; def zone; 'CEST'; end; end

      in_zone 'Asia/Tbilisi' do

        #expect(
        #  EtOrbi::EoTime.make(t).to_debug_s
        #).to eq(
        #  'ot 2016-11-01 12:30:09 +04:00 dst:false'
        #)
        expect {
          EtOrbi.make_time(t).to_debug_s
        }.to raise_error(ArgumentError, /cannot determine timezone from "CEST"/)
      end
    end

    it 'accepts a UTC Time' do

      expect(
        EtOrbi.make_time(
          Time.utc(2016, 11, 01, 12, 30, 9)
        ).to_debug_s
      ).to eq(
        'ot 2016-11-01 12:30:09 +00:00 dst:false'
      )
    end

    it 'accepts a Date' do

      expect(
        EtOrbi.make_time(
          Date.new(2016, 11, 01)
        ).to_debug_s
      ).to eq(
        EtOrbi::EoTime.new(
          Time.local(2016, 11, 01).to_f, nil
        ).to_debug_s
      )
    end

    it 'accepts a String' do

      expect(
        EtOrbi.make_time(
          '2016-11-01 12:30:09')
      ).to eq(
        EtOrbi::EoTime.new(
          Time.local(2016, 11, 01, 12, 30, 9).to_f, nil)
      )
    end

    it 'accepts a String (Zulu)' do

      expect(
        EtOrbi.make_time('2016-11-01 12:30:09Z')
      ).to eq(
        EtOrbi::EoTime.new(
          Time.utc(2016, 11, 01, 12, 30, 9).to_f, 'Zulu')
      )
    end

    it 'accepts a String (ss+01:00)' do

      expect(
        EtOrbi.make_time('2016-11-01 12:30:09+01:00')
          .to_debug_s
      ).to eq(
        'ot 2016-11-01 12:30:09 +01:00 dst:false'
      )
    end

    it 'accepts a String (ss-01)' do

      expect(
        EtOrbi.make_time('2016-11-01 12:30:09-01')
          .to_debug_s
      ).to eq(
        'ot 2016-11-01 12:30:09 -01:00 dst:false'
      )
    end

    it 'accepts a duration String'# do
#
#      expect(
#        EtOrbi.make_time('1h')
#      ).to be_between(
#        Time.now + 3600 - 1, Time.now + 3600 + 1
#      )
#    end
  #
  # String parsing is fugit's job. Et-orbi should be a dependency of
  # fugit, not the other way around. When fugit is present, this
  # spec should succeed, else it should not.

    it 'accepts a Numeric' do

      expect(
        EtOrbi.make_time(3600)
      ).to be_between(
        Time.now + 3600 - 1, Time.now + 3600 + 1
      )
    end

    it 'accepts an array (as Time.local does)' do

      t = in_zone('Europe/Moscow') { EtOrbi.make([ 2017, 2, 28 ]) }

      expect(t.to_s).to eq('2017-02-28 00:00:00 +0300')
    end

    it 'accepts an array of arguments (as Time.local does)' do

      t = in_zone('Europe/Moscow') { EtOrbi.make(2017, 1, 31) }

      expect(t.to_s).to eq('2017-01-31 00:00:00 +0300')
    end

    it 'rejects unparseable input' do

      expect {
        EtOrbi.make_time('xxx')
      #}.to raise_error(ArgumentError, 'couldn\'t parse "xxx"')
      }.to raise_error(ArgumentError, 'no time information in "xxx"')
        # straight out of Time.parse()

      expect {
        EtOrbi.make_time(Object.new)
      }.to raise_error(ArgumentError, /\Acannot turn /)
    end
  end
end

