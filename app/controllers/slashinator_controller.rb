class SlashinatorController < ApplicationController
  before_action :set_todo, only: [:show, :update, :destroy]

  # GET /slash
  def index
    resp = {'status': 200, 'message': 'It works'}
    render :json => resp, :status => 200
    #json_response(resp)
  end

  def parseit
    puts "PASSED PARAMS: #{params}"
    token = params[:token]
    Rails.logger.info "Year: #{Time.now.year}"
    Rails.logger.info "%%%%%%% ALL PARAMS : #{params}"
    resp = {'status': 200, 'message': 'GOT IT!', 'read':token}

    resp = get_which_instance

    render :json => resp, :status => 200
  end
  
  private

  def get_which_instance
    instance_json = {
    "text": "Did you want to run a test?",
    "attachments": [
        {
            "text": "Choose environment to execute test.",
            "fallback": "You need to specify test instance.",
            "callback_id": "tupshop_instance",
            "color": "#3AA3E3",
            "attachment_type": "default",
            "actions": [
                {
                    "name": "instance",
                    "text": "Production",
                    "type": "button",
                    "value": "prod"
                },
                {
                    "name": "instance",
                    "text": "Release",
                    "type": "button",
                    "value": "release"
                },
				{
                    "name": "instance",
                    "text": "Zoolander",
                    "type": "button",
                    "value": "zoolander"
                },
                {
                    "name": "instance",
                    "text": "cancel",
                    "style": "danger",
                    "type": "button",
                    "value": "cancel"
                }
            ]
        }
    ]
}
  return instance_json
  end

end
