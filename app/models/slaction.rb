require 'json'
require 'file_db'

class Slaction

  attr_accessor :response_url, :token, :attachment_id, :user_id, :user_name, 
    :channel_id, :channel_name, :callback_id, :team_id, :team_domain, :action, :action_value
  
  def initialize(posted_params)
    slice_payload(posted_params)
   # @payload = posted_params['payload']
   # {"payload"=>"{\"actions\":[{\"name\":\"instance\",\"type\":\"select\",\"selected_options\":[{\"value\":\"wrangler\"}]}],\"callback_id\":\"selected_instance\",\"team\":{\"id\":\"T0250S4K1\",\"domain\":\"thredup\"},\"channel\":{\"id\":\"C02FLF1AX\",\"name\":\"web\"},\"user\":{\"id\":\"U4XKUCBGQ\",\"name\":\"ibarra\"},\"action_ts\":\"1496426454.989130\",\"message_ts\":\"1496426451.095813\",\"attachment_id\":\"1\",\"token\":\"o6ogpOUawimQXxlfbTKA44dQ\",\"is_app_unfurl\":false,\"response_url\":\"https:\\/\\/hooks.slack.com\\/actions\\/T0250S4K1\\/192108252661\\/jTRzeM5xSe7cpiloT1vn5GaY\"}"}
  end

  def to_string
    all_data = @action + " :: " + @callback_id + " :: " + @action_value
    Rails.logger.info "Slaction : #{all_data}"
  end

  private

  def slice_payload(payload)
    file_db = FileDB.new()

    payload.has_key?('actions') ? slice_action(payload[:actions]) : @action = ''
    @response_url = payload[:response_url]
    @token = payload[:token]
    @attachment_id = payload[:attachment_id]
    @user_id = payload[:user][:id]
    @user_name = payload[:user][:name]
    @channel_id = payload[:channel][:id]
    @channel_name = payload[:channel][:name]
    @callback_id = payload[:callback_id]
    @team_id = payload[:team][:id]
    @team_domain = payload[:team][:name]
    @callback_id = payload[:callback_id]
  end

  def slice_action(action_payload)
    Rails.logger.info "SlICE ACT PAYLOAD : #{action_payload}"
    first_action = action_payload[0]
    Rails.logger.info "JUST ACTION : #{first_action.keys}"
    @action = first_action[:name]
    @action_value = first_action[:selected_options][0][:value]
  end

  def slice_user(user_payload)
    @user_id = user_payload[:id]
    @user_name = user_payload[:name]
  end
  
  def init_values
  end

end