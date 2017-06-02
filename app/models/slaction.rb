require 'json'

class Slaction

  attr_accessor :response_url, :token, :attachment_id, :user_id, :user_name, 
    :channel_id, :channel_name, :callback_id, :team_id, :team_domain, :action
  
  def initialization(posted_params)
    slice_payload(posted_params['payload'].to_s)
   # @payload = posted_params['payload']
   # {"payload"=>"{\"actions\":[{\"name\":\"instance\",\"type\":\"select\",\"selected_options\":[{\"value\":\"wrangler\"}]}],\"callback_id\":\"selected_instance\",\"team\":{\"id\":\"T0250S4K1\",\"domain\":\"thredup\"},\"channel\":{\"id\":\"C02FLF1AX\",\"name\":\"web\"},\"user\":{\"id\":\"U4XKUCBGQ\",\"name\":\"ibarra\"},\"action_ts\":\"1496426454.989130\",\"message_ts\":\"1496426451.095813\",\"attachment_id\":\"1\",\"token\":\"o6ogpOUawimQXxlfbTKA44dQ\",\"is_app_unfurl\":false,\"response_url\":\"https:\\/\\/hooks.slack.com\\/actions\\/T0250S4K1\\/192108252661\\/jTRzeM5xSe7cpiloT1vn5GaY\"}"}
  end

  def exec

  end

  def to_string
    all_data = @action + " :: " + @callback_id
    Rails.logger.info "Slaction : #{all_data}"
  end

  private

  def slice_payload(json_string)
    data = JSON.parse(json_string)
    @action = data['action']
    @callback_id = data['callback_id']
  end
  
end