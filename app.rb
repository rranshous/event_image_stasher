require 'eventstore'
require 'sequel'
require 'base64'
require 'json'

$stdout.sync = true

CONNSTRING = ENV['EVENTSTORE_URL'] || 'http://0.0.0.0:2113'
WRITE_DIR = ENV['WRITE_DIR'] || './data'

database_url = ENV['DATABASE_URL'] || "sqlite://#{File.join(WRITE_DIR,'images.db')}"
DB = Sequel.connect(database_url, :encoding => 'utf-8')

begin
  DB.create_table :images do
    primary_key :id
    String      :path
    String      :href
    timestamp   :created_at

    index       :href, :unique => true
  end
rescue Sequel::DatabaseError
  puts "IMAGES TABLE EXISTS"
end

class Image < Sequel::Model
  def data
    File.read(path)
  end
end

SLEEP_TIME = 10
start_at = 0
last_start_at = nil
loop do
  if last_start_at == start_at
    puts "SLEEPING: #{SLEEP_TIME}"
    sleep SLEEP_TIME
  end
  last_start_at = start_at
  eventstore = EventStore::Client.new(CONNSTRING)
  puts "START_AT: #{start_at}"
  events = eventstore.resume_read('new-images', start_at, 100)
  events.each do |event|
    href = event[:body]["href"]
    puts "CHECKING: #{href}"
    image = Image.where(href: href).first
    if image
      puts "FOUND IMAGE: #{image}"
    else
      puts "DOWNLOADING: #{href}"
      response = HTTParty.get(href)
      image_data = response.parsed_response
      filename = Base64.encode64(href)
      out_path = File.join WRITE_DIR, filename
      puts "WRITING: #{out_path}"
      File.write(out_path, image_data)
      image = Image.new(href: href, path: out_path)
      image.save
      puts "SAVED: #{image.id} :: #{href} :: #{out_path}"
    end
    start_at = event[:id]
  end
end
