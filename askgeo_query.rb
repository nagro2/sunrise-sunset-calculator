# askgeo_query.rb


require 'date'
require 'addressable/uri'
require 'json'
require 'rest-client'
lat = 51.4770228
lon = -0.0001147
base_url = 'http://api.askgeo.com/v1'
account_id = '1738' # my account for now but you can get one it's free
# my api key too
api_key = '7f33e4f2a928bc460cbb997fe3b5cb0b30fc7abebe16422e6b267989f80297d0'
url = "#{base_url}/#{account_id}/#{api_key}/query.json?points="
query = "#{lat},#{lon};databases=Astronomy"
addr = Addressable::URI.escape(url + query)
rest_resource = JSON.parse(RestClient.get(addr))
puts status = rest_resource['message']
results = rest_resource['data']
if status == 'ok'
  astronomy = {}
  results[0].fetch('Astronomy').each do |key, value|
    astronomy.store(key, value)
  end
end
sunrise = astronomy.fetch('TodaySunriseIso8601')
transit = astronomy.fetch('TodaySolarNoonIso8601')
sunset = astronomy.fetch('TodaySunsetIso8601')
puts sunrise
puts transit
puts sunset

