require 'sinatra'
require 'base64'
require 'json'

$stdout.sync = true

WRITE_DIR = ENV['WRITE_DIR'] || './data'

get '/' do
  content_type :json
  Dir.glob(File.join(WRITE_DIR,'*'))
    .map{|p| File.basename(p) }
    .to_json
end

get '/links' do
  content_type :html
  Dir.glob(File.join(WRITE_DIR,'*'))
    .map{|p| File.basename(p) }
    .map{|n| "<a href='/#{n}'>#{n}</a><br/>" }
end

head '/:image_name_encoded' do |image_name_encoded|
  file_path = File.join WRITE_DIR, image_name_encoded
  halt 404 unless File.exists? file_path
  halt 200
end

get '/:image_name_encoded' do |image_name_encoded|
  file_path = File.join WRITE_DIR, image_name_encoded
  halt 404 unless File.exists? file_path
  mime_type = `file --mime-type #{file_path} | cut -d' ' -f2`
  type = mime_type.split('/').last.chomp.to_sym
  content_type type
  File.read(file_path)
end

post '/:image_name_encoded' do |image_name_encoded|
  file_path = File.join WRITE_DIR, image_name_encoded
  puts "FILEPATH: #{file_path}"
  File.write file_path, params['data'][:tempfile].read
  puts "WROTE: #{file_path}"
  content_type :text
  image_name_encoded
end
