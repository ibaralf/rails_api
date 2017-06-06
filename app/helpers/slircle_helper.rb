require 'net/http'
require 'json'
require 'uri'
require_relative '../models/file_db'

module SlircleHelper

  def handle_slash_command(req_params)
    file_db = FileDB.new()
    #file_db.team_id = req_params[:team_id]
    #file_db.channel_id = req_params[:channel_id]
    #file_db.channel_name = req_params[:channel_name]
    #file_db.user_id = req_params[:user_id]
    #file_db.user_name = req_params[:user_name]
    file_db.add(req_params)
    get_instance_message
  end

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
              { "text": "All",
                "value": "all" },
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

  def handle_action(posted_params)
    Rails.logger.info "HANDLE_ACTION : #{posted_params.class}"
    Rails.logger.info "HANDLE_ACTION : #{posted_params}"
    @file_db = FileDB.new()
    @file_db.action_add(posted_params)
    #slaction = Slaction.new(posted_params)
    
    case @file_db.get_value(:last_action)
    when 'instance'
      action_instance_selected(posted_params)
      #post_circleci(slaction.action_value)
    when 'spec_selected'
      action_spec_selected(posted_params)
    else 
      Rails.logger.info "ERROR Unhandled slack action: #{@file_db.action_name}"
    end
    
  end


  private

  def action_instance_selected(req_params)
    @file_db.action_add(req_params)
    actval = @file_db.get_action_value(:instance)
    Rails.logger.info "ACTION VALUE: #{actval}"
    if actval == 'cancel'
      res = { "text": "You cancelled test. Hope you try it again later."}
      return res
    end
    get_specs_message
  end

  def action_spec_selected(req_params)
    @file_db.action_add(req_params)
    post_circleci()
  end

  def post_circleci()
    instance = @file_db.get_action_value(:instance)
    specs = @file_db.get_action_value(:spec_selected)
    Rails.logger.info "API To CircleCI : #{instance} :: #{specs}"
    uri = URI("https://circleci.com/api/v1/project/thredup/tup-shop-automation/tree/master?circle-token=dc72a15d4d7e1cb81f62057f3f72620417620742")
    #uri = URI.parse(url)
    param_body = {"build_parameters":{"RUN_BUILD":"true","USER_INSTANCE": instance, "SELECTED_SPECS": specs}}.to_json
    #http = Net::HTTP.new(uri.host, uri.port)
    #req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    #req.body = param_body
    #req = Net::HTTP::Post.new uri 
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = param_body
    respo = Net::HTTP.start(uri.host, uri.port, 
        :use_ssl => uri.scheme == 'https') {|http| http.request req}
    json_data = JSON.parse(respo.body)
    Rails.logger.info "CIRCLECI CLASS : #{respo.class}"
    Rails.logger.info "CIRCLECI CLASS : #{respo.body}"
    Rails.logger.info "CIRCLECI CLASS : #{json_data['build_url']}"
    result_link = { "text": "See results in #{json_data['build_url']}"}
    return result_link
  end


  

end
