require 'sinatra'
require 'base64'

$stdout.sync = true

WRITE_DIR = ENV['WRITE_DIR'] || './data'

get '/:image_name_encoded' do |image_name_encoded|
  puts "IMAGE: #{image_name_encoded}"
  file_path = File.join WRITE_DIR, image_name_encoded
  halt 404 unless File.exists? file_path
  File.read(file_path)
end

post '/:image_name_encoded' do |image_name_encoded|
  puts "IMAGE HREF: #{Base64.urlsafe_decode64(image_name_encoded)}"
  file_path = File.join WRITE_DIR, image_name_encoded
  puts "EXISTS" if File.exists? file_path
  File.write file_path, params['data'][:tempfile].read
  content_type :text
  image_name_encoded
end
