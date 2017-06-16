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
        post_status(site_code)
      end
    elsif site_code == '-1'
      sleep(300)
      perform(url, up_post, down_post)
    else
      Rails.logger.info "Site status down - #{site_code}"
      if down_post
        post_status(site_code)
      end
      if debug_exit
        post_status(site_code)
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

  # TODO: Replace image snapshot - use gem 
  def post_status(scode='200')
    ts = Time.zone.now.strftime("%Y-%m-%d_%H:%M:%S")
    if scode =='200'
      text_msg = "ThredUP site is back UP - status code 200"
      image_msg = "Uptime #{ts}"
      image_url = 'https://i.imgur.com/uF1jxol.jpg'
    else
      text_msg = "ThredUP site is back UP - status code 200"
      image_msg = "Uptime #{ts}"
      image_url = 'https://i.imgur.com/VadPR4R.png'
    end
    chan_url = Tokenz.get_channel_url
    payload = {"text": text_msg, "attachments": [{ "text": image_msg, "image_url": image_url}]}
    request_hash = {:url => chan_url, :payload => payload}
    HttpHelper.post(request_hash)
  end

  # Returns HTTP status as String
  def get_site_status(site_url)
    req_start = Time.now
    get_response = HttpHelper.get(site_url)
    if get_response != '-1'
      req_duration = Time.now - req_start
      Rails.logger.info "STATUS: #{get_response.code} :: response time - #{req_duration}"
      if req_duration > 4.0
        payload = { "text": "Thredup.com load time exceeded threshold - #{req_duration} sec" }
        request_hash = {:url => Tokenz.get_channel_url('testing'), :payload => payload}
        HttpHelper.post(request_hash)
      end
      return get_response.code.to_s
    end
    return '-1'
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
