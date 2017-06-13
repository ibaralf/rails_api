require "net/https"
require "uri"

class SiteCheckJob 
  include SuckerPunch::Job

  # Get site status - logic as follows:
  # If status is good (200) exit loop
  # If status bad, recursively check status every 60 sec
  # If cannot get status (-1), retry after 5 minute wait
  # TODO: Cleanup, DRY, create smaller methods
  def perform(url, up_post, down_post)

    site_code = get_site_status(url)
    if site_code == '200'
      if up_post
        post_up_status
      end
    elsif site_code == '-1'
      sleep(300)
      perform(url, up_post, down_post)
    else
      Rails.logger.info "Site status down - #{site_code}"
      if down_post
        post_down_status(site_code)
      end
      if debug_exit
        post_up_status
      else
        sleep(60)
        perform(url, true, false)
      end
    end
    delete_run_file

  end

  def self.is_running?
    full_path = File.dirname(__FILE__) + "/../../site_check_running.txt"
    if File.file?(full_path)
      return true
    end
    return false
  end

  def self.create_run_file
    full_path = File.dirname(__FILE__) + "/../../site_check_running.txt"
    if ! File.file?(full_path)
      File.open(full_path, "w") {}
    end
  end

  private

  def post_up_status()
    chan_url = Tokenz.get_channel_url
    ts = Time.new.strftime("%Y-%m-%d_%H:%M:%S")
    phash = {:channel_url => chan_url, 
      :text => "ThredUP site is back UP - status code 200", :img_url => 'https://i.imgur.com/uF1jxol.jpg',
      :img_text => "Uptime #{ts}"}
    post_status(phash)
  end

  def post_down_status(scode)
    chan_url = Tokenz.get_channel_url
    ts = Time.new.strftime("%Y-%m-%d_%H:%M:%S")
    phash = {:channel_url => chan_url, 
      :text => "ThredUP site down - status code #{scode}", :img_url => 'https://i.imgur.com/VadPR4R.png',
      :img_text => "Downtime #{ts}"}
    post_status(phash)
  end

  # Returns HTTP status as String
  def get_site_status(site_url)
    uri = URI.parse(site_url)
    req_start = Time.now
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    begin
      res = http.request(request)
    rescue StandardError
      Rails.logger.info "Request error for site #{site_url}"
      return '-1'
    end
    req_duration = Time.now - req_start
    puts "STATUS: #{res.code} :: response time - #{req_duration}"
    if req_duration > 7.0
      hh = {:channel_url => Tokenz.get_channel_url('testing'), :text => "Thredup.com load time exceeded threshold - #{req_duration} sec"}
      post_time_warning(hh)
    end
    return res.code.to_s
  end

  # phash = {:channel_url, :text, :img_url, :img_text}
  def post_status(phash)

    channel_url = phash[:channel_url]
    uri = URI.parse(channel_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
    param_body = { "text": phash[:text], "attachments": [{ "text": phash[:img_text], "image_url": phash[:img_url] }] }.to_json
    req.body = param_body
    begin
      respo = Net::HTTP.start(uri.host, uri.port, 
        :use_ssl => uri.scheme == 'https') {|http| http.request req}
    rescue StandardError
      resulta = { "text": "CircleCI API returned an error - check status of circleCI. Thanks."}
      Rails.logger.info "STATUS ERROR : "
      return resulta
    end
    do_retry = respo.kind_of? Net::HTTPSuccess
  end

  def post_time_warning(phash)

    channel_url = phash[:channel_url]
    uri = URI.parse(channel_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
    param_body = { "text": phash[:text] }.to_json
    req.body = param_body
    begin
      respo = Net::HTTP.start(uri.host, uri.port, 
        :use_ssl => uri.scheme == 'https') {|http| http.request req}
    rescue StandardError
      resulta = { "text": "Post warning to Slack resulted in error."}
      Rails.logger.info "SLack POST error : "
      return resulta
    end
    do_retry = respo.kind_of? Net::HTTPSuccess
  end

  def debug_exit
    file_check("stop_check")
  end
  
  def delete_run_file
    file_delete("site_check_running.txt")
  end

  def file_delete(name_of_file)
    full_path = File.dirname(__FILE__) + "/../../" + name_of_file
    if File.file?(full_path)
      return File.delete(full_path)
    end
    return false
  end

  def file_check(name_of_file)
    full_path = File.dirname(__FILE__) + "/../../" + name_of_file
    if File.file?(full_path)
      return true
    end
    return false
  end
  
end
