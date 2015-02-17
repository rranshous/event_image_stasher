require 'eventstore'
require 'base64'

$stdout.sync = true

CONNSTRING = ENV['EVENTSTORE_URL'] || 'http://0.0.0.0:2113'
WRITE_DIR = ENV['WRITE_DIR'] || './data'
eventstore = EventStore::Client.new(CONNSTRING)

SLEEP_TIME = 10
start_at = 0
last_start_at = nil
begin
  loop do
    if last_start_at == start_at
      puts "SLEEPING: #{SLEEP_TIME}"
      sleep SLEEP_TIME
    end
    last_start_at = start_at
    puts "START_AT: #{start_at}"
    events = eventstore.resume_read('new-images', start_at, 100)
    events.each do |event|
      href = event[:body]["href"]
      filename = Base64.urlsafe_encode64(href)
      out_path = File.join WRITE_DIR, filename
      puts "CHECKING: #{href}"
      if File.exists? out_path
        puts "FOUND IMAGE: #{out_path}"
      else
        puts "DOWNLOADING: #{href}"
        response = HTTParty.get(href)
        image_data = response.parsed_response
        puts "WRITING: #{out_path}"
        File.write(out_path, image_data)
        puts "SAVED #{href} :: #{out_path}"
        eventstore.write_event('images', 'downloaded', { href: href })
      end
      start_at = event[:id]
    end
  end
rescue => ex
  puts "EXCEPTION: #{ex}"
  raise
end
