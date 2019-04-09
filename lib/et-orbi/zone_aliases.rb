
module EtOrbi

  class << self

    def tweak_zone_name(name)

      return name unless (name.match(/./) rescue nil)
        # to prevent invalid byte sequence in UTF-8..., gh-15

      normalize(name) ||
      unzz(name) ||
      name
    end

    def abbreviate_zone_name(name)

      return nil unless (name.match(/./) rescue nil)
        # to prevent invalid byte sequence in UTF-8..., gh-15

      return nil unless name.match(/\A[A-Z]{2,3}/)
      return nil if name.match(/\AUTC/)

      ZONE_ABBREVIATIONS.each do |abbr, zone|
        return zone if name[0, abbr.length] == abbr
      end

      nil
    end

    protected

    def normalize(name)

      ZONE_ALIASES[name.sub(/ Daylight /, ' Standard ')]
    end

    def unzz(name)

      m = name.match(/\A([A-Z]{3,4})([+-])(\d{1,2}):?(\d{2})?\z/)
      return nil unless m

      abbs = [ m[1] ]; a = m[1]
      abbs << "#{a}T" if a.size < 4

      off =
        (m[2] == '+' ? 1 : -1) *
        (m[3].to_i * 3600 + (m[4] || '0').to_i * 60)

      t = Time.now
      twin = Time.utc(t.year, 1, 1) # winter
      tsum = Time.utc(t.year, 7, 1) # summer

      tz_all
        .each { |tz|
          abbs.each { |abb|
            per = tz.period_for_utc(twin)
            return tz.name \
              if per.abbreviation.to_s == abb && per.utc_total_offset == off
            per = tz.period_for_utc(tsum)
            return tz.name \
              if per.abbreviation.to_s == abb && per.utc_total_offset == off } }

      nil
    end
  end

  # https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones
  # https://support.microsoft.com/en-ca/help/973627/microsoft-time-zone-index-values
  # https://ss64.com/nt/timezones.html

  #ZONE_ABBS =
  #  if tzid_gem = Gem.loaded_specs['tzinfo-data']
  #    Dir[
  #      File.join(tzid_gem.full_gem_path, 'lib/tzinfo/data/definitions/*.rb')
  #    ]
  #      .inject([]) { |a, pa|
  #        fn = File.basename(pa, '.rb')
  #        a << fn.gsub(/__[mp]__/) { |m| m == '__m__' ? '-' : '+' } \
  #          if fn.match(/\A[A-Z]{2,3}.*/)
  #        a }
  #  else
  #    nil
  #  end
    #
    # keep that in the fridge, may prove useful later on...

  ZONE_ALIASES = {
    'Coordinated Universal Time' => 'UTC',
    'Afghanistan Standard Time' => 'Asia/Kabul',
    'FLE Standard Time' => 'Europe/Helsinki',
    'Central Europe Standard Time' => 'Europe/Prague',
    'UTC-11' => 'Etc/GMT+11',
    'W. Europe Standard Time' => 'Europe/Rome',
    'W. Central Africa Standard Time' => 'Africa/Lagos',
    'SA Western Standard Time' => 'America/La_Paz',
    'Pacific SA Standard Time' => 'America/Santiago',
    'Argentina Standard Time' => 'America/Argentina/Buenos_Aires',
    'Caucasus Standard Time' => 'Asia/Yerevan',
    'AUS Eastern Standard Time' => 'Australia/Sydney',
    'Azerbaijan Standard Time' => 'Asia/Baku',
    'Eastern Standard Time' => 'America/New_York',
    'Arab Standard Time' => 'Asia/Riyadh',
    'Bangladesh Standard Time' => 'Asia/Dhaka',
    'Belarus Standard Time' => 'Europe/Minsk',
    'Romance Standard Time' => 'Europe/Paris',
    'Central America Standard Time' => 'America/Belize',
    'Atlantic Standard Time' => 'Atlantic/Bermuda',
    'Venezuela Standard Time' => 'America/Caracas',
    'Central European Standard Time' => 'Europe/Warsaw',
    'South Africa Standard Time' => 'Africa/Johannesburg',
    #'UTC' => 'Etc/UTC', # 'UTC' is good as is
    'E. South America Standard Time' => 'America/Sao_Paulo',
    'Central Asia Standard Time' => 'Asia/Almaty',
    'Singapore Standard Time' => 'Asia/Singapore',
    'Greenwich Standard Time' => 'Africa/Monrovia',
    'Cape Verde Standard Time' => 'Atlantic/Cape_Verde',
    'SE Asia Standard Time' => 'Asia/Bangkok',
    'SA Pacific Standard Time' => 'America/Bogota',
    'China Standard Time' => 'Asia/Shanghai',
    'Myanmar Standard Time' => 'Asia/Yangon',
    'E. Africa Standard Time' => 'Africa/Nairobi',
    'Hawaiian Standard Time' => 'Pacific/Honololu',
    'E. Europe Standard Time' => 'Europe/Nicosia',
    'Tokyo Standard Time' => 'Asia/Tokyo',
    'Egypt Standard Time' => 'Africa/Cairo',
    'SA Eastern Standard Time' => 'America/Cayenne',
    'GMT Standard Time' => 'Europe/London',
    'Fiji Standard Time' => 'Pacific/Fiji',
    'West Asia Standard Time' => 'Asia/Tashkent',
    'Georgian Standard Time' => 'Asia/Tbilisi',
    'GTB Standard Time' => 'Europe/Athens',
    'Greenland Standard Time' => 'America/Godthab',
    'West Pacific Standard Time' => 'Pacific/Guam',
    'Mauritius Standard Time' => 'Indian/Mauritius',
    'India Standard Time' => 'Asia/Kolkata',
    'Iran Standard Time' => 'Asia/Tehran',
    'Arabic Standard Time' => 'Asia/Baghdad',
    'Israel Standard Time' => 'Asia/Jerusalem',
    'Jordan Standard Time' => 'Asia/Amman',
    'UTC+12' => 'Etc/GMT-12',
    'Korea Standard Time' => 'Asia/Seoul',
    'Middle East Standard Time' => 'Asia/Beirut',
    'Central Standard Time (Mexico)' => 'America/Mexico_City',
    'Ulaanbaatar Standard Time' => 'Asia/Ulaanbaatar',
    'Morocco Standard Time' => 'Africa/Casablanca',
    'Namibia Standard Time' => 'Africa/Windhoek',
    'Nepal Standard Time' => 'Asia/Kathmandu',
    'Central Pacific Standard Time' => 'Etc/GMT-11',
    'New Zealand Standard Time' => 'Pacific/Auckland',
    'Arabian Standard Time' => 'Asia/Dubai',
    'Pakistan Standard Time' => 'Asia/Karachi',
    'Paraguay Standard Time' => 'America/Asuncion',
    'Pacific Standard Time' => 'America/Los_Angeles',
    'Russian Standard Time' => 'Europe/Moscow',
    'Samoa Standard Time' => 'Pacific/Pago_Pago',
    'UTC-02' => 'Etc/GMT+2',
    'Sri Lanka Standard Time' => 'Asia/Kolkata',
    'Syria Standard Time' => 'Asia/Damascus',
    'Taipei Standard Time' => 'Asia/Taipei',
    'Tonga Standard Time' => 'Pacific/Tongatapu',
    'Turkey Standard Time' => 'Asia/Istanbul',
    'Montevideo Standard Time' => 'America/Montevideo' }

  ZONE_ABBREVIATIONS =
    begin

      zone_abb_rex = /\A[A-Z]{2,3}/

      t0 = Time.parse('2019-01-01').utc
      t1 = Time.parse('2019-08-01').utc

      TZInfo::Timezone.all
        .inject([]) { |a, z|
          zn = z.name
          zn3 = zn[0, 3]
          p0a = z.period_for_utc(t0).abbreviation
          p1a = z.period_for_utc(t1).abbreviation
#p [ zn, p0a, p1a ]
          if zn.match(zone_abb_rex) && zn3 != 'US/' && zn3 != 'GMT'
            a << [ p0a, zn ] if p0a != 'UTC' && p0a.match(zone_abb_rex)
            a << [ p1a, zn ] if p1a != 'UTC' && p1a.match(zone_abb_rex)
            a << [ zn, zn ] if zn.index('-') == nil
          end
          a }
        .uniq
        .sort_by { |a, _| - a.length }
    end
#pp ZONE_ABBREVIATIONS; exit 0
end

