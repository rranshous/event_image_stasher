require 'base64'
require 'httparty'
require 'persistent_httparty'
require 'httmultiparty'

class ImageStasher
  include HTTMultiParty
  persistent_connection_adapter

  def self.get_data image_href
    image_href_encoded = encode image_href
    self.get("#{host}/#{image_href_encoded}").parsed_response
  end

  def self.get_data_by_key image_href_encoded
    self.get("#{host}/#{image_href_encoded}").parsed_response
  end

  def self.set_data image_href, image_data
    image_href_encoded = encode image_href
    upload = UploadIO.new(StringIO.new(image_data), "image", "image_href_encoded")
    resp = self.post("#{host}/#{image_href_encoded}", query: {
      data: upload
    })
    resp.code
  end

  def self.list
    self.get("#{host}/").parsed_response
  end

  def self.exists? image_href
    image_href_encoded = encode image_href
    rsp = self.head("#{host}/#{image_href_encoded}")
    return rsp.code == 200
  end

  private
  def self.host
    ENV['IMAGE_STASHER_URL']
  end
  def self.encode image_href
    Base64.urlsafe_encode64(image_href)
  end
end
