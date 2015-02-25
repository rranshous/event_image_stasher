require 'streamworker'
require_relative 'image_stasher'

name 'image-downloader'
handle 'new-images' do |state, event|

  href = event[:body]["href"]
  log "href: #{href}"

  if href.nil? || href.chomp.length == 0
    log "no href, skipping"
    next
  end

  if ImageStasher.exists? href
    log "exists, skipping #{href}"

  else
    response = HTTParty.get(href)
    if response.code != 200
      log "bad download: #{response}"
      next
    end
    image_data = response.parsed_response
    log "posting to stash: #{image_data.length}"
    rsp = ImageStasher.set_data href, image_data
    log "successful post #{rsp}"
    emit 'images', 'downloaded', { href: href, bytesize: image_data.length }
  end
end
