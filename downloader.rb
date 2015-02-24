require 'streamworker'
require_relative 'image_stasher'

handle 'new-images' do |state, event|

  href = event[:body]["href"]

  if href.nil? || href.chomp.length == 0
    puts "NO HREF"
    next
  end

  puts "CHECKING: #{href}"

  if ImageStasher.exists? href
    puts "FOUND IMAGE: #{href}"

  else
    puts "DOWNLOADING: #{href}"
    response = HTTParty.get(href)
    if response.code != 200
      puts "BAD IMAGE DOWNLOAD: #{response}"
      next
    end
    image_data = response.parsed_response
    puts "WRITING: #{image_data.length}"
    ImageStasher.set_data href, image_data
    puts "SAVED #{href} #{image_data.length}"
    emit 'images', 'downloaded', { href: href, bytesize: image_data.length }
  end
end
