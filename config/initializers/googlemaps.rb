
maps_key_file = "#{Rails.root}/config/google_maps.txt"
if File.exist? maps_key_file
  maps_key = File.read(maps_key_file).strip
end

if maps_key.present?
  MAPS_JS_URL = "https://maps.googleapis.com/maps/api/js?key=#{maps_key}"
else
  MAPS_JS_URL = 'https://maps.googleapis.com/maps/api/js'
end
