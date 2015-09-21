
def sunrisesunset(riseorset, month, day, year, latitude, longitude)
	include Math


	# Sunrise Sunset calculator by Nick Agro
	# adapted from the algorithm below
	# Note that accuracy of the algorithm degrades for north of 60 degrees north and south of
	# 60 degrees south.

            #    http://williams.best.vwh.net/sunrise_sunset_algorithm.htm


            #Sunrise/Sunset Algorithm

            #Source:
            #	Almanac for Computers, 1990
            #	published by Nautical Almanac Office
            #	United States Naval Observatory
            #	Washington, DC 20392

            #Inputs:
            #	day, month, year:      date of sunrise/sunset
            #	latitude, longitude:   location for sunrise/sunset
            #	zenith:                Sun's zenith for sunrise/sunset
            #	  offical      = 90 degrees 50'
            #	  civil        = 96 degrees
            #	  nautical     = 102 degrees
            #	  astronomical = 108 degrees
            #
            #NOTE: longitude is positive for East and negative for West
            #   NOTE: the algorithm assumes the use of a calculator with the
            #   trig functions in "degree" (rather than "radian") mode. Most
            #   programming languages assume radian arguments, requiring back
            #   and forth convertions. The factor is 180/pi. So, for instance,
            #   the equation ra = atan(0.91764 * tan(l)) would be coded as ra
            #   = (180/pi)*atan(0.91764 * tan((pi/180)*l)) to give a degree
            #   answer with a degree input for l.


            zenith = 90.0 + (50.0 / 60.0) # for official sunrise / sunset per table below
            #zenith = 108
            #	zenith:                Sun's zenith for sunrise/sunset
            #	  offical      = 90 degrees 50'
            #	  civil        = 96 degrees
            #	  nautical     = 102 degrees
            #	  astronomical = 108 degrees

            #1. first calculate the day of the year
            n1 = (275 * month / 9.0).floor
            n2 = ((month + 9) / 12.0).floor
            n3 = 1 + ((year - 4 * (year / 4.0).floor + 2) / 3.0).floor
            n = n1 - (n2 * n3) + day - 30

            #2. convert the longitude to hour value and calculate an approximate time

            lngHour = longitude / 15.0

            #if rising time is desired:
            if riseorset == "rise" 
                t = n + ((6 - lngHour) / 24.0)
            else
                #if setting time is desired:
                t = n + ((18 - lngHour) / 24.0)
            end



            #3. calculate the Sun's mean anomaly

            m = (0.9856 * t) - 3.289

            #4. calculate the Sun's true longitude

            l = m + (1.916 * sin((PI / 180) * m)) + (0.02 * sin((PI / 180) * 2 * m)) + 282.634
            #NOTE: l potentially needs to be adjusted into the range [0,360) by adding/subtracting 360
            if l >= 360 
                l = l - 360
            else
                if l < 0 
                    l = l + 360
                end
            end

            #5a. calculate the Sun's right ascension

            ra = (180 / PI) * atan(0.91764 * tan((PI / 180) * l))
            #NOTE: ra potentially needs to be adjusted into the range [0,360) by adding/subtracting 360
            if ra >= 360 
                ra = ra - 360
            else
                if ra < 0 
                    ra = ra + 360
                end
            end

            #5b. right ascension value needs to be in the same quadrant as l

            lquadrant = ((l / 90.0).floor) * 90
            raquadrant = ((ra / 90.0).floor) * 90
            ra = ra + (lquadrant - raquadrant)

            #5c. right ascension value needs to be converted into hours

            ra = ra / 15.0

            #6. calculate the Sun's declination

            sinDec = 0.39782 * sin((PI / 180) * l)
            cosDec = cos(asin(sinDec)) #per Nick this should not need conversion to degrees

            #7a. calculate the Sun's local hour angle

            cosH = (cos((PI / 180) * zenith) - (sinDec * sin((PI / 180) * latitude))) / (cosDec * cos((PI / 180) * latitude))

            #if (cosH > 1) 
            #the sun never rises on this location (on the specified date)
	    #print "cosH= ", cosH

	    if cosH > 1
		if riseorset == "rise"
			return[0,0]
			else
			return [23,59]
			end
		end

            # if (cosH < -1) 
            #the sun never sets on this location (on the specified date)

	    if cosH < -1
		if riseorset == "rise"
			return[0,0]
			else
			return [23,59]
			end
	    	end

            #7b. finish calculating h and convert into hours

            if riseorset == "rise" 
                #if rising time is desired:
                h = 360 - (180 / PI) * acos(cosH)
            else
                #if setting time is desired:
                h = (180 / PI) * acos(cosH)
            end

            h = h / 15.0

            #8. calculate local mean time of rising/setting

            t = h + ra - (0.06571 * t) - 6.622

            #9. adjust back to UTC

            ut = t - lngHour
            #NOTE: ut potentially needs to be adjusted into the range [0,24) by adding/subtracting 24
            if ut >= 24 
                ut = ut - 24
            else
                if ut < 0 
                    ut = ut + 24
                end
            end

            #10. convert ut value to local time zone of latitude/longitude

            localOffset = -4 #NY is normally 5 hrs behind ut, but with DST it is currently 4 hours (as of 9/21/15)

            localT = ut + localOffset

	    # Nick note localT may need to be adjusted into the range 0,24 by adding/subtracting 24
            if localT >= 24 
                localT = localT - 24
            else
                if localT < 0 
                    localT = localT + 24
                end
            end


            if riseorset == "rise" 
                risehour = localT.to_int
                riseminute = (localT - risehour) * 60
                if riseminute >= 60 
                    riseminute = riseminute - 60
                    risehour = risehour + 1
                end
                if risehour < 0 
                    risehour = risehour + 24
                end
		return risehour, riseminute
            else
                sethour = localT.to_int
                setminute = (localT - sethour) * 60
                if setminute >= 60 
                    setminute = setminute - 60
                    sethour = sethour + 1
                end
                if sethour < 0 
                    sethour = sethour + 24
                end
		return sethour, setminute
            end
end

print "\nSunrise-Sunset demo:\n"
ri = sunrisesunset("rise", 9, 21, 2015, 40.93, -73.03)
se = sunrisesunset("set", 9, 21, 2015, 40.93, -73.03)
print "for Sept 21, 2015, Sunrise ", ri[0],":", ri[1].round,", Sunset ", se[0],":", se[1].round,"\n\n"


