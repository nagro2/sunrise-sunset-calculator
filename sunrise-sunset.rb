
def sunrisesunset(riseorset, month, day, year, latitude, longitude)
  include Math

  # Sunrise Sunset calculator by Nick Agro
  # adapted from the algorithm below
  # Note that accuracy of the algorithm degrades for north of 60 degrees north
  # and south of 60 degrees south.
  #
  #    http://williams.best.vwh.net/sunrise_sunset_algorithm.htm
  #
  # Sunrise/Sunset Algorithm
  #
  # Source:
  #	Almanac for Computers, 1990
  #	published by Nautical Almanac Office
  #	United States Naval Observatory
  #	Washington, DC 20392
  #
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

  zenith = 90.0 + (50.0 / 60.0) # for official sunrise / sunset per table below
  # zenith = 108
  #	zenith:                Sun's zenith for sunrise/sunset
  #	  offical      = 90 degrees 50'
  #	  civil        = 96 degrees
  #	  nautical     = 102 degrees
  #	  astronomical = 108 degrees

  # 1. first calculate the day of the year
  n1 = (275 * month / 9.0).floor
  n2 = ((month + 9) / 12.0).floor
  n3 = 1 + ((year - 4 * (year / 4.0).floor + 2) / 3.0).floor
  n = n1 - (n2 * n3) + day - 30

  # 2. convert the longitude to hour value and calculate an approximate time

  lng_hour = longitude / 15.0

  # if rising time is desired:
  t = if riseorset == 'rise'
        n + ((6 - lng_hour) / 24.0)
      else
        # if setting time is desired:
        n + ((18 - lng_hour) / 24.0)
      end

  # 3. calculate the Sun's mean anomaly

  m = (0.9856 * t) - 3.289

  # 4. calculate the Sun's true longitude

  l = m +
      (1.916 * sin((PI / 180) * m)) + (0.02 * sin((PI / 180) * 2 * m)) + 282.634
  # NOTE:
  # l potentially needs to be adjusted into the range [0,360) by
  # adding/subtracting 360
  if l >= 360
    l -= 360
  elsif l < 0
    l += 360
  end

  # 5a. calculate the Sun's right ascension

  ra = (180 / PI) * atan(0.91764 * tan((PI / 180) * l))
  # NOTE:
  # ra potentially needs to be adjusted into the range [0,360) by
  # adding/subtracting 360
  if ra >= 360
    ra -= 360
  elsif ra < 0
    ra += 360
  end

  # 5b. right ascension value needs to be in the same quadrant as l

  lquadrant = (l / 90.0).floor * 90
  raquadrant = (ra / 90.0).floor * 90
  ra += (lquadrant - raquadrant)

  # 5c. right ascension value needs to be converted into hours

  ra /= 15.0

  # 6. calculate the Sun's declination

  sin_dec = 0.39782 * sin((PI / 180) * l)
  # per Nick this should not need conversion to degrees
  cos_dec = cos(asin(sin_dec))

  # 7a. calculate the Sun's local hour angle

  cos_h = (cos((PI / 180) * zenith) -
  (sin_dec * sin((PI / 180) * latitude))) /
          (cos_dec * cos((PI / 180) * latitude))

  # if (cos_h > 1)
  # the sun never rises on this location (on the specified date)
  # print "cos_h= ", cos_h

  return [0, 0] if cos_h > 1 && riseorset == 'rise'
  return [23, 59] if cos_h > 1

  # if (cos_h < -1)
  # the sun never sets on this location (on the specified date)

  return [0, 0] if cos_h < -1 && riseorset == 'rise'
  return [23, 59] if cos_h < -1

  # 7b. finish calculating h and convert into hours

  h = if riseorset == 'rise'
        # if rising time is desired:
        360 - (180 / PI) * acos(cos_h)
      else
        # if setting time is desired:
        (180 / PI) * acos(cos_h)
      end

  h /= 15.0

  # 8. calculate local mean time of rising/setting

  t = h + ra - (0.06571 * t) - 6.622

  # 9. adjust back to UTC

  ut = t - lng_hour
  # NOTE:
  # ut potentially needs to be adjusted into the range [0,24) by
  # adding/subtracting 24
  if ut >= 24
    ut -= 24
  elsif ut < 0
    ut += 24
  end

  # 10. convert ut value to local time zone of latitude/longitude

  # NY is normally 5 hrs behind ut, but with DST it is currently 4
  # hours (as of 9/28/12)
  local_offset = -4

  local_t = ut + local_offset

  # Nick note local_t may need to be adjusted into the range 0,24 by
  # adding/subtracting 24
  if local_t >= 24
    local_t -= 24
  elsif local_t < 0
    local_t += 24
  end

  # print local_t, "\n"
  if riseorset == 'rise'
    risehour = local_t.to_int
    riseminute = (local_t - risehour) * 60
    if riseminute >= 60
      riseminute -= 60
      risehour += 1
    end
    risehour += 24 if risehour < 0
    return risehour, riseminute
  else
    sethour = local_t.to_int
    setminute = (local_t - sethour) * 60
    if setminute >= 60
      setminute -= 60
      sethour += 1
    end
    sethour += 24 if sethour < 0
    return sethour, setminute
  end
end

time = Time.new

# 40.93 = NY, 0 = equator, 60 is highest latitude where the algorithm works well
lat = 40.93
lon = -73.03 # -73.03 = NY

ri = sunrisesunset('rise', time.month, time.day, time.year, lat, lon)
se = sunrisesunset('set', time.month, time.day, time.year, lat, lon)
se[0] -= 12 if se[0] > 12
output = 'For ' +
         time.month.to_s + '/' +
         time.day.to_s + '/' +
         time.year.to_s +
         ' Sunrise ' +
         ri[0].to_s + ':' +
         ri[1].round.to_s +
         ', Sunset ' +
         se[0].to_s + ':' +
         se[1].round.to_s + "\n"

print output
