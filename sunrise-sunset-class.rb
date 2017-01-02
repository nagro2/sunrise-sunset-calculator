#
# Sunrise Sunset calculator by Nick Agro
# adapted from the algorithm below
# Note that accuracy of the algorithm degrades for north of 60 degrees north
# and south of 60 degrees south.

#    http://williams.best.vwh.net/sunrise_sunset_algorithm.htm

# Sunrise/Sunset Algorithm

# Source:
#	Almanac for Computers, 1990
#	published by Nautical Almanac Office
#	United States Naval Observatory
#	Washington, DC 20392

# Inputs:
#	day, month, year:      date of sunrise/sunset
#	latitude, longitude:   location for sunrise/sunset
#	zenith:                Sun's zenith for sunrise/sunset
#	  offical      = 90 degrees 50'
#	  civil        = 96 degrees
#	  nautical     = 102 degrees
#	  astronomical = 108 degrees
#
# NOTE: longitude is positive for East and negative for West
#   NOTE: the algorithm assumes the use of a calculator with the
#   trig functions in "degree" (rather than "radian") mode. Most
#   programming languages assume radian arguments, requiring back
#   and forth convertions. The factor is 180/pi. So, for instance,
#   the equation ra = atan(0.91764 * tan(l)) would be coded as ra
#   = (180/pi)*atan(0.91764 * tan((pi/180)*l)) to give a degree
#   answer with a degree input for l.
class SunRiseSunSet
  include Math
  attr_accessor :riseorset, :time, :yday, :latitude, :longitude, :local_offset
  def initialize(riseorset, time, latitude, longitude, local_offset)
    @riseorset = riseorset
    @time = time
    @yday = time.yday
    @lat = latitude
    @lon = longitude
    @loffset = local_offset
  end

  def zenith
    90.0 + (50.0 / 60.0) # for official sunrise / sunset per table below
    #	zenith: Sun's zenith for sunrise/sunset
    #	  offical      = 90 degrees 50'
    #	  civil        = 96 degrees
    #	  nautical     = 102 degrees
    #	  astronomical = 108 degrees
  end

  # 1. first calculate the day of the year
  def n
    @yday # should have the right julian day added. WIP
  end

  # 2. convert the longitude to hour value and calculate an approximate time
  def lng_hour
    @lon / 15.0
  end

  # if rising time is desired:
  def t
    if @riseorset == 'rise'
      n + ((6 - lng_hour) / 24.0)
    else
      # if setting time is desired:
      n + ((18 - lng_hour) / 24.0)
    end
  end

  # 3. calculate the Sun's mean anomaly
  def ma
    357.5291 + (0.9856 * t)
  end

  # 4. calculate the Sun's true longitude
  def tl
    l = ma + (1.916 * sin((PI / 180) * ma)) +
        (0.02 * sin((PI / 180) * 2 * ma)) + 282.634
    # NOTE: l potentially needs to be adjusted into the
    # range [0,360) by adding/subtracting 360
    if l >= 360
      l -= 360
    elsif l < 0
      l += 360
    end
    l
  end

  # 5a. calculate the Sun's right ascension
  def ra
    r = (180 / PI) * atan(0.91764 * tan((PI / 180) * tl))
    # NOTE: ra potentially needs to be adjusted into the
    # range [0,360) by adding/subtracting 360
    if r >= 360
      r -= 360
    elsif r < 0
      r += 360
    end
    r
  end

  # 5b. right ascension value needs to be in the same quadrant as l
  # 5c. right ascension value needs to be converted into hours
  def eot
    lquadrant = (tl / 90).floor * 90
    raquadrant = (ra / 90).floor * 90
    r = ra + (lquadrant - raquadrant)
    r / 15.0
  end

  # 6. calculate the Sun's declination
  def sin_dec
    0.39782 * sin((PI / 180) * tl)
  end

  def cos_dec
    cos(asin(sin_dec)) # per Nick this should not need conversion to degrees
  end

  # 7a. calculate the Sun's local hour angle
  def cos_h
    (cos((PI / 180) * zenith) - (sin_dec * sin((PI / 180) * @lat))) /
      (cos_dec * cos((PI / 180) * @lat))
  end

  def lat_h
    if cos_h > 1
      # the sun never rises on this location (on the specified date)
      print 'cos_h = ', cos_h
      return [0, 0] if @riseorset == 'rise' &&
                       cos_h > 1 ||
                       @riseorset == 'rise' &&
                       cos_h < -1
    else # the sun never sets on this location (on the specified date)
      return [23, 59] if cos_h > 1 || cos_h < -1
    end
  end

  # 7b. finish calculating h and convert into hours
  def ha
    h = (180 / PI) * acos(cos_h)
    h = 360 - (180 / PI) * acos(cos_h) if @riseorset == 'rise'
    h / 15.0
  end

  # 8. calculate local mean time of rising/setting
  def mt
    ha + eot - (0.06571 * t) - 6.622
  end

  # 9. adjust back to UTC
  def utc
    ut = mt - lng_hour
    # NOTE: ut potentially needs to be adjusted into the range [0,24) by adding/subtracting 24
    if ut >= 24
      ut -= 24
    elsif ut < 0
      ut += 24
    end
    ut
  end

  # 10. convert ut value to local time zone of latitude/longitude
  def local_t
    local = utc + @loffset
    # Nick note local_t may need to be adjusted into the range 0,24 by adding/subtracting 24
    if local >= 24
      local -= 24
    elsif local < 0
      local += 24
    end
    local
  end

  # print local_t, "\n"
  def local_t_out
    lat_h
    if @riseorset == 'rise'
      risehour = local_t.to_int
      riseminute = (local_t - risehour) * 60
      if riseminute >= 60
        riseminute -= 60
        risehour += 1
      end
      risehour += 24 if risehour < 0
      [risehour, riseminute]
    else
      sethour = local_t.to_int
      setminute = (local_t - sethour) * 60
      if setminute >= 60
        setminute -= 60
        sethour += 1
      end
      sethour += 24 if sethour < 0
      [sethour, setminute]
    end
  end

  def output
    print "For #{@time.month}/#{@time.day}/#{@time.year} \n"
    if @riseorset == 'rise'
      printf("Sunrise %2.0f:%02.0f\n", local_t_out[0], local_t_out[1].round)
    elsif @riseorset == 'set'
      local_t_out[0] -= 12 if local_t_out[0] > 12
      printf("Sunset %2.0f:%02.0f\n", local_t_out[0], local_t_out[1].round)
    end
  end
end

@time = Time.now

lat = 51.4770228
lon = -0.0001147
zone = 0

@ri = SunRiseSunSet.new('rise', @time, lat, lon, zone).output
@se = SunRiseSunSet.new('set', @time, lat, lon, zone).output
