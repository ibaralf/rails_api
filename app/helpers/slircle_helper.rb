require 'net/http'
require 'json'
require 'uri'
require_relative '../models/file_db'
require_relative '../models/tokenz'

module SlircleHelper
  
  
  # REFACTOR!!! - new methods to handle if instance - yes/no, if 
  # 
  def handle_slash_command(req_params)
    set_option_vars
    @file_db = FileDB.new()
    @file_db.add(req_params)
    parsed = parse_text(@file_db.get_value(:text))
    if parsed["is_empty"]
      return get_instance_message
    else
      if @instances.values.include?(parsed["instance"])
        @file_db.user_add_instance(req_params[:user_id], parsed["instance"])
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

  def handle_action(posted_params)
    set_option_vars
    #Rails.logger.info "HANDLE_ACTION : #{posted_params}"
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

  private

  def token_authenticate
    @tokenz = Tokenz.new
    if request.remote_ip == "127.0.0.1"
      return true
    elsif ! is_authorized?(params)
      render :json => {'status': 401, 'message': "Unauthorized" }, :status => 401
    end
  end

  def is_authorized?(req_params)
    token = nil
    if req_params[:token].nil? && ! req_params[:payload].nil?
      payload = JSON.parse(req_params[:payload])
      token = payload['token']
    else
      token = req_params[:token]
    end
    if @tokenz.slashapp_token != token
      return false
    end
    return true
  end

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
    selspecs = @file_db.get_action_value(:spec_selected).strip
    formatted_specs = convert_specs_string(selspecs.split(" "))
    post_circleci(formatted_specs)
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
    url = @tokenz.circleci_url + @tokenz.circleci_token
    payload = {"build_parameters":{"RUN_BUILD":"true","USER_INSTANCE": instance, "SELECTED_SPECS": specs}}
    request_hash = {:url => url, :payload => payload}
    respo = HttpHelper.post(request_hash)
    json_data = JSON.parse(respo.body)
    #Rails.logger.info "CIRCLECI CLASS : #{respo.body}"
    #Rails.logger.info "CIRCLECI CLASS : #{json_data['build_url']}"
    result_link = { "text": "See results in #{json_data['build_url']}"}
    return result_link
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

  def set_option_vars
    @instances = {"Burgundy" => "burgundy", "EC2" => "ec2", "Selfoss" => "selfoss", "Stage3" => "stage3", "Thredtest" => "thredtest", 
                  "Wrangler" => "wrangler", "Zoolander" => "zoolander", "Production" => "production", "Release" => "release"}
    @specs = {"My Thredup- Sizes" => "my_thredup_sizes_spec", "Search" => "search_spec", "Checkout" => "checkout_spec", 
              "Signup" => "signup_spec", "Cleanout" => "cleanout_spec", "Favorites" => "favorites_spec"}
    @specs_available = ["sample_test", "my_thredup_sizes_spec", "search_spec", "checkout_spec",
                    "signup_spec", "amazon_login_spec", "facebook_login_spec", "cleanout_spec", "favorites_spec"]
  end

  def get_instance_dropdowns
    rarr = []
    @instances.keys.each do |unkey|
      rarr << { "text": unkey, "value": @instances[unkey] }
    end
    return rarr
  end

  def get_spec_dropdowns
    rarr = []
    all_specs = ""
    @specs.keys.each do |unkey|
      all_specs.concat("#{@specs[unkey]} ")
      rarr << { "text": unkey, "value": @specs[unkey] }
    end
    rarr.unshift({"text": "All", "value": all_specs.strip})
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
    pattern = /.*\.rb/
    rval = ""
    specs_arr.each do |unspec|
      if pattern =~ unspec
        rval << "#{unspec} "
      else
        rval << "#{unspec}.rb "
      end
    end
    return rval.strip
  end


#######################  SLACK MESSAGES #########################
# TODO: Put in a YAML file 
#

  def get_instance_message
    dropdown_options = get_instance_dropdowns
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
            "options": dropdown_options },
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
    dropdown_options = get_spec_dropdowns

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
            "options": dropdown_options }
       ]
    } ] }
    return instance_json
  end


end
