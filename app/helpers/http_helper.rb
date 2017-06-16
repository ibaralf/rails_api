require "net/https"
require "uri"

class HttpHelper

  def self.get(site_url)
    uri = URI.parse(site_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    begin
      res = http.request(request)
    rescue StandardError
      Rails.logger.info "GET Request error for site #{site_url}"
      return '-1'
    end
  end

  def self.post(req_hash)
    uri = URI.parse(req_hash[:url])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
    request.body = req_hash[:payload].to_json
    begin
      respo = Net::HTTP.start(uri.host, uri.port, 
        :use_ssl => uri.scheme == 'https') {|http| http.request(request)}
    rescue StandardError
      resulta = { "text": "Post to Slack resulted in error."}
      Rails.logger.info "Net HTTP Error"
      return resulta
    end
    return respo
  end

end
