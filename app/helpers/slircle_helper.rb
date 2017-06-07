require 'net/http'
require 'json'
require 'uri'
require_relative '../models/file_db'
require_relative '../models/tokenz'

module SlircleHelper
  
  
  # REFACTOR!!! - new methods to handle if instance - yes/no, if 
  # 
  def handle_slash_command(req_params)
    @file_db = FileDB.new()
    @file_db.add(req_params)
    parsed = parse_text(@file_db.get_value(:text))
    Rails.logger.info "Parsed Value: #{parsed}"
    if parsed["is_empty"]
      return get_instance_message
    else
      set_class_vars
      if @instances.values.include?(parsed["instance"])
        Rails.logger.info "USER PASSED: #{parsed["instance"]}"
        @file_db.user_add_instance(parsed["instance"])
        passed_specs = get_specs(parsed["specs"])
        if passed_specs.empty?
          return get_specs_message
        else
          spec_string = convert_specs_string(passed_specs)
          post_circleci(spec_string)
        end
      else
        Rails.logger.info "INSTANCE NOT FOUND: #{parsed["instance"]}"
        return get_instance_message
      end
    end
  end

  # TODO: 
  #  implement verify token (slashapp token)
  def handle_action(posted_params)
    Rails.logger.info "HANDLE_ACTION : #{posted_params.class}"
    Rails.logger.info "HANDLE_ACTION : #{posted_params}"
    @file_db = FileDB.new()
    @file_db.action_add(posted_params)
    
    case @file_db.get_value(:last_action)
    when 'instance'
      action_instance_selected(posted_params)
    when 'spec_selected'
      action_spec_selected(posted_params)
    else 
      Rails.logger.info "ERROR Unhandled slack action: #{@file_db.action_name}"
    end
    
  end

  def get_tokens()
    tokenz = Tokenz.new()
    tokenz.to_s
  end


  private

  def action_instance_selected(req_params)
    @file_db.action_add(req_params)
    actval = @file_db.get_action_value(:instance)
    Rails.logger.info "ACTION VALUE: #{actval}"
    if actval == 'cancel'
      res = { "text": "You cancelled the test. Hope you try it again later."}
      return res
    end
    get_specs_message
  end

  def action_spec_selected(req_params)
    @file_db.action_add(req_params)
    post_circleci()
  end

  # TODO:
  #  - catch Net:: exceptions
  #  - refactor and clean up
  def post_circleci(user_specs = nil)
    instance = @file_db.get_action_value(:instance)
    if user_specs.nil?
      specs = @file_db.get_action_value(:spec_selected)
    else
      specs = user_specs
    end
    
    Rails.logger.info "API To CircleCI : #{instance} :: #{specs}"
    base_url = 'https://circleci.com/api/v1/project/thredup/tup-shop-automation/tree/master?circle-token='
    cci_token = Tokenz.get_circleci_token
    url = base_url + cci_token
    uri = URI(url)
    param_body = {"build_parameters":{"RUN_BUILD":"true","USER_INSTANCE": instance, "SELECTED_SPECS": specs}}.to_json
    #http = Net::HTTP.new(uri.host, uri.port)
    #req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    #req.body = param_body
    #req = Net::HTTP::Post.new uri 
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = param_body
    begin
      respo = Net::HTTP.start(uri.host, uri.port, 
        :use_ssl => uri.scheme == 'https') {|http| http.request req}
    rescue StandardError
      resulta = { "text": "CircleCI API returned an error - check status of circleCI. Thanks."}
      return resulta
    end
    json_data = JSON.parse(respo.body)
    Rails.logger.info "CIRCLECI CLASS : #{respo.class}"
    Rails.logger.info "CIRCLECI CLASS : #{respo.body}"
    Rails.logger.info "CIRCLECI CLASS : #{json_data['build_url']}"
    result_link = { "text": "See results in #{json_data['build_url']}"}
    return result_link
  end

  #######################  SLACK MESSAGES #########################

  def get_instance_message
    instance_json = {
      "text": "Did you want to run a test?",
      "attachments": [ {  
        "text": "Choose environment to execute test.",
        "fallback": "You need to specify test instance.",
        "callback_id": "selected_instance",
        "color": "#3AA3E3",
        "attachment_type": "default",
        "actions": [ 
          { "name": "instance",
          "text": "Production",
          "type": "button",
          "value": "production" },
          { "name": "instance",
          "text": "Release",
          "type": "button",
          "value": "release" },

          { "name": "instance",
            "text": "Select environment",
            "type": "select",
            "options": [
              { "text": "Burgundy",
                "value": "burgundy" },
              { "text": "EC2",
                "value": "ec2" },
              { "text": "Selfoss",
              "value": "selfoss" },
              { "text": "Stage3",
                "value": "stage3" },
              { "text": "Thredtest",
                "value": "thredtest" },
              { "text": "Wrangler",
                "value": "wrangler" },
              { "text": "Zoolander",
                "value": "zoolander" }
            ] },

          { "name": "instance",
          "text": "cancel",
          "style": "danger",
          "type": "button",
          "value": "cancel" }
       ]
    } ] }
    return instance_json
  end

  def get_specs_message
    instance_json = {
      "text": "Select spec test to execute?",
      "attachments": [ {  
        "text": "Select spec test.",
        "fallback": "Defaults to run all spec.",
        "callback_id": "selected_spec",
        "color": "#3AA3E3",
        "attachment_type": "default",
        "actions": [ 
          { "name": "spec_selected",
            "text": "Tests to run",
            "type": "select",
            "options": [
              { "text": "Sample Test",
                "value": "sample_test.rb" },
              { "text": "My Thredup Preference",
                "value": "my_thredup_sizes_spec.rb" },
              { "text": "Search and Size filter",
              "value": "search_spec.rb" },
              { "text": "Checkout",
                "value": "checkout_spec.rb" },
              { "text": "New User Signup",
                "value": "signup_spec.rb" }
            ] }
       ]
    } ] }
    return instance_json
  end

  def parse_text(txt)
    txt.downcase!
    rhash = {"is_empty" => true, "instance" => "", "specs" => [], "all_text" => []}
    if txt.nil? ||txt.empty?
      return rhash
    else
      split_txt = txt.split(" ")
      rhash["is_empty"] = false
      rhash["instance"] = split_txt[0]
      rhash["specs"] = split_txt[1..-1]
      rhash["all_text"] = split_txt
      return rhash
    end

  end

  def set_class_vars
    @instances = {"Production" => "production", "Release" => "release", "Burgundy" => "burgundy", "EC2" => "ec2",
              "Selfoss" => "selfoss", "Stage3" => "stage3", "Thredtest" => "thredtest", "Wrangler" => "wrangler",
              "Zoolander" => "zoolander"}
    @specs_available = ["sample_test", "my_thredup_sizes_spec", "search_spec", "checkout_spec",
                    "signup_spec", "amazon_login_spec", "facebook_login_spec"]
  end

  def add_rb_extensions(arrspecs)
    pattern = /.*\.rb/
    rarr = []
    arrspecs.each do |unspec|
      if pattern =~ unspec
        rarr << unspec
      else
        rarr << unspec + ".rb"
      end
    end
    return rarr
  end
                  
  def get_specs(pspec)
    valid_specs = []
    pspec.each do |unspec|
      if @specs_available.include?(unspec)
        valid_specs << unspec + ".rb"
      end
    end
    return valid_specs
  end

  def convert_specs_string(specs_arr)
    rval = ""
    specs_arr.each do |unspec|
      rval << "#{unspec} "
    end
    return rval.strip
  end

end
