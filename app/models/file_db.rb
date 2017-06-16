require 'yaml'

class FileDB

  LOCAL_FILEDB = 'slack_data.yml'
  
  def initialize(filetag = LOCAL_FILEDB)
    @filetag = filetag
    @slack_data = read_data(filetag)
  end

  # Saves response from slash command
  def add(params_data)
    @user_hash = get_user(params_data[:user_id])
    @user_hash[:user_name] = params_data[:user_name]
    @user_hash[:user_id] = params_data[:user_id]
    @user_hash[:text] = params_data[:text]
    @user_hash[:command] = params_data[:command]
    @user_hash[:team_id] = params_data[:team_id]
    @user_hash[:team_domain] = params_data[:team_domain]
    @user_hash[:channel_id] = params_data[:channel_id]
    @user_hash[:channel_name] = params_data[:channel_name]
    @user_hash[:slack_respurl] = params_data[:response_url]
    save_data(@filetag)
  end

  # Saves response from slash action. 
  # NOTE!!!: Slash passes the payload value as a String
  # Ex: {"payload”:”{“actions":[{"name":"instance","type":"select","selected_options":[{"value":"wrangler"}]}],
  # "callback_id":"selected_instance","team":{"id":"T0250S4K1","domain":"thredup"},"channel":{"id":"C02FLF1AX","name":"web"},
  # "user":{"id":"U4XKUCBGQ","name":"ibarra"},"action_ts":"1496433898.883423","message_ts":"1496433887.483392","attachment_id":"1",
  # "token":"o6ogpOUawimQXxlfbTKA44dQ","is_app_unfurl":false,"response_url":"https://hooks.slack.com/actions/T0250S4K1/192013544835/sN4bih0YVaigiYMBtptrTc1J"}"}
  def action_add(payload)
    @user_hash = get_user(payload['user']['id'])
    action_name = payload['actions'][0]['name']
    
    actions_hash = {}
    actions_hash[:name] = action_name
    actions_hash[:type] = payload['actions'][0]['type']
    if actions_hash[:type] == 'select'
      actions_hash[:value] = payload['actions'][0]['selected_options'][0]['value']
    else
      actions_hash[:value] = payload['actions'][0]['value']
    end
    actions_hash[:respurl] = payload['response_url']
    @user_hash[action_name.to_sym] = actions_hash
    @user_hash[:last_action] = action_name
    @user_hash[:attachment_id] = payload['attachment_id']
    @user_hash[:callback_id] = payload['callback_id']
    save_data(@filetag)
  end

  def user_add_instance(instance_passed)
    actions_hash = {}
    actions_hash[:name] = 'instance'
    actions_hash[:type] = 'user_passed'
    actions_hash[:value] = instance_passed
    @user_hash[:instance] = actions_hash
    # puts "SAVING DATA #{@user_hash}"
    save_data(@filetag)
  end

  def get_action_value(action_sym)
    @user_hash[action_sym][:value]
  end

  def get_value(symtag)
    @user_hash[symtag]
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

  def self.get_token(params_data)
  end
  

  private

  def read_data(fname)
    full_path = File.dirname(__FILE__) + "/../../" + fname
    if File.file?(full_path)
      existing_yaml = YAML.load_file(fname)
      if existing_yaml
        return existing_yaml
      else
        return []
      end
    else
      return []
    end
  end

  def save_data(fname)
    File.write(fname, @slack_data.to_yaml)
  end
  
  
end
