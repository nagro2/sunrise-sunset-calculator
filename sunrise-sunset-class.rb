#!/usr/bin/env ruby
require 'date'
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
# time:         date of sunrise/sunset is calculated
# latitude:     location for sunrise/sunset
# longitude:    location for sunrise/sunset
# zenith:       Sun's zenith for sunrise/sunset
#	             offical      = 90 degrees 50'
#	             civil        = 96 degrees
#	             nautical     = 102 degrees
#	             astronomical = 108 degrees
# local_offset: local zone time difference
# riseorset:    select which function rise or set
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
  attr_accessor :time, :latitude, :longitude, :zenith, :riseorset, :local_offset
  def initialize(time, latitude, longitude, zenith, riseorset, local_offset)
    @time = time
    @lat = latitude
    @lon = longitude
    @zenith = zenith
    @riseorset = riseorset
    @loffset = local_offset
  end

  def cos_zenith
    case @zenith
    when 'official'
      cos((90.0 + (50.0 / 60.0)) * PI / 180)
    when 'civil'
      cos(96 * PI / 180)
    when 'nautical'
      cos(102 * PI / 180)
    when 'astronomical'
      cos(108 * PI / 180)
    end
  end

  # 1. first calculate the day of the year
  # should have the right julian day added.
  def n
    jd = Date.parse("#{@time.year}-#{@time.month}-#{@time.day}").jd
    @yday = jd - 2_451_545.0
  end

  # 2. convert the longitude to hour value and calculate an approximate time
  def lng_hour
    @lon / 15.0
  end

  # if rising time is desired:
  def d
    if @riseorset == 'rise'
      n + ((6 - lng_hour) / 24.0)
    else
      # if setting time is desired:
      n + ((18 - lng_hour) / 24.0)
    end
  end

  # 3. calculate the Sun's mean anomaly
  def ma
    357.5291 + (0.9856 * d)
  end

  def ta
    ma + (1.916 * sin((PI / 180) * ma)) +
      (0.02 * sin((PI / 180) * 2 * ma))
  end

  # 4. calculate the Sun's true longitude
  def tl
    l = ta + 282.634 # this might be
    # argument of perihelion.
    # But that changes like anything else. Probably should be factored out
    # because the Earth is not that inclined to the Sun in its orbit
    # NOTE: l potentially needs to be adjusted into the
    # range [0,360) by adding/subtracting 360
    if l >= 360
      l -= 360
    elsif l < 0
      l += 360
    end
    l * PI / 180
  end

  # 5a. calculate the Sun's right ascension
  def ra
    r = atan(0.91764 * tan(tl))
    # NOTE: ra potentially needs to be adjusted into the
    # range [0,360) by adding/subtracting 360
    if r >= (2 * PI)
      r -= (2 * PI)
    elsif r < 0
      r += (2 * PI)
    end
    r
  end

  # 5b. right ascension value needs to be in the same quadrant as tl
  # 5c. right ascension value needs to be converted into hours
  def ra_hours
    lquadrant = (tl / 1.5708).floor * 1.5708
    raquadrant = (ra / 1.5708).floor * 1.5708
    (ra + lquadrant - raquadrant) / 0.2618
  end

  # 6. calculate the Sun's declination
  def sin_dec
    0.39782 * sin(tl)
  end

  def cos_dec
    cos(asin(sin_dec)) # per Nick this should not need conversion to degrees
  end

  # 7a. calculate the Sun's local hour angle
  def cos_h
    lat = (PI / 180) * @lat
    (cos_zenith - (sin_dec * sin(lat))) /
      (cos_dec * cos(lat))
  end

  def lat_h
    if @riseorset == 'rise' && (cos_h > 1 || cos_h < -1)
      # the sun never rises on this location (on the specified date)
      print 'sun never rises on this location'
      [0, 0]
    elsif cos_h > 1 || cos_h < -1
      # the sun never sets on this location (on the specified date)
      print 'sun never sets on this location'
      [23, 59]
    end
  end

  # 7b. finish calculating h and convert into hours
  def ha
    h = acos(cos_h)
    h = (2 * PI) - acos(cos_h) if @riseorset == 'rise'
    h / 0.2618
  end

  # 8. calculate local time of rising/setting
  def mt
    ha + ra_hours - (0.06571 * d) - 6.622
  end

  # 9. adjust back to UTC
  def utc
    ut = mt - lng_hour
    # NOTE: ut potentially needs to be adjusted into the range [0,24)
    #       by adding/subtracting 24
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
    # Nick note: local_t may need to be adjusted into the range 0,24
    #           by adding/subtracting 24
    if local >= 24
      local -= 24
    elsif local < 0
      local += 24
    end
    local
  end

  def rise_t
    risehour = local_t.to_int
    riseminute = (local_t - risehour) * 60
    if riseminute >= 60
      riseminute -= 60
      risehour += 1
    end
    risehour += 24 if risehour < 0
    [risehour, riseminute]
  end

  def set_t
    sethour = local_t.to_int
    setminute = (local_t - sethour) * 60
    if setminute >= 60
      setminute -= 60
      sethour += 1
    end
    sethour += 24 if sethour < 0
    [sethour, setminute]
  end

  # print local_t, "\n"
  def local_t_out
    lat_h
    if @riseorset == 'rise'
      rise_t
    else
      set_t
    end
  end

  def output_rise
    printf("For #{@date} #{@zenith} sunrise %2.0f:%02.0f\n",
           local_t_out[0], local_t_out[1].round)
  end

  def output_set
    local_t_out[0] -= 12 if local_t_out[0] > 12
    printf("For #{@date} #{@zenith} sunset %2.0f:%02.0f\n",
           local_t_out[0], local_t_out[1].round)
  end

  def output
    @date = "#{@time.month}/#{@time.day}/#{@time.year}"
    if @riseorset == 'rise'
      output_rise
    elsif @riseorset == 'set'
      output_set
    end
  end
end

@time = Time.now

lat = 41.94
lon = -88.75
zone = -5

SunRiseSunSet.new(@time, lat, lon, 'official', 'rise', zone).output
SunRiseSunSet.new(@time, lat, lon, 'official', 'set', zone).output
SunRiseSunSet.new(@time, lat, lon, 'civil', 'rise', zone).output
SunRiseSunSet.new(@time, lat, lon, 'civil', 'set', zone).output
SunRiseSunSet.new(@time, lat, lon, 'nautical', 'rise', zone).output
SunRiseSunSet.new(@time, lat, lon, 'nautical', 'set', zone).output
SunRiseSunSet.new(@time, lat, lon, 'astronomical', 'rise', zone).output
SunRiseSunSet.new(@time, lat, lon, 'astronomical', 'set', zone).output
