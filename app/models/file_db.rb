require 'yaml'

class FileDB
  attr_accessor :team_id, :team_domain, :channel_id, :channel_name, :user_id, :user_name, :command, :text, :slash_respurl

  LOCAL_FILEDB = 'slack_data.yml'
  #TOKEN_FILES = token_data.yml
  
  def initialize(filetag = LOCAL_FILEDB)
    @filetag = filetag
    @slack_data = read_data(filetag)
  end

  # Saves response from slash command
  def add(params_data)
    user_hash = get_user(params_data[:user_id])
    user_hash[:user_name] = params_data[:user_name]
    user_hash[:user_id] = params_data[:user_id]
    user_hash[:text] = params_data[:text]
    user_hash[:command] = params_data[:command]
    user_hash[:team_id] = params_data[:team_id]
    user_hash[:team_domain] = params_data[:team_domain]
    user_hash[:channel_id] = params_data[:channel_id]
    user_hash[:channel_name] = params_data[:channel_name]
    user_hash[:slash_respurl] = params_data[:response_url]
    save_data(@filetag)
  end

  # Saves response from slash action
  # {"payload”:”{“actions":[{"name":"instance","type":"select","selected_options":[{"value":"wrangler"}]}],
  # "callback_id":"selected_instance","team":{"id":"T0250S4K1","domain":"thredup"},"channel":{"id":"C02FLF1AX","name":"web"},
  # "user":{"id":"U4XKUCBGQ","name":"ibarra"},"action_ts":"1496433898.883423","message_ts":"1496433887.483392","attachment_id":"1",
  # "token":"o6ogpOUawimQXxlfbTKA44dQ","is_app_unfurl":false,"response_url":"https://hooks.slack.com/actions/T0250S4K1/192013544835/sN4bih0YVaigiYMBtptrTc1J"}"}
  def action_add(payload)
    user_hash = get_user(payload[:user][:id])
    user_hash[:action_name] = payload[:actions][0][:name]
    user_hash[:action_type] = payload[:actions][0][:type]
    user_hash[:action_value] = payload[:actions][0][:selected_options][0][:value]
    user_hash[:action_respurl] = payload[:response_url]
    user_hash[:attachment_id] = payload[:attachment_id]
    user_hash[:callback_id] = payload[:callback_id]
    save_data(@filetag)
  end

  def get_user(id_of_user)
    udata = @slack_data.detect {|uhash| uhash[:user_id] == id_of_user}
    if udata.nil?
      Rails.logger.info "New User : #{id_of_user}"
      new_user = {:user_id => id_of_user}
      @slack_data << new_user
      return new_user
    else
      Rails.logger.info "EXIST User : #{udata}"
      return udata
    end
  end

  private

  def read_data(fname)
    full_path = File.dirname(__FILE__) + "/../../" + fname
    if File.file?(full_path)
      return YAML.load_file(fname)
    else
      return []
    end
  end

  def save_data(fname)
    File.write(fname, @slack_data.to_yaml)
  end
  
  
end
