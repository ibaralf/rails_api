class SlircleController < ApplicationController
  include SlircleHelper

  # GET /slash
  def index
    resp = {'status': 200, 'message': 'You\'re OK, it works.'}
    render :json => resp, :status => 200
    #json_response(resp)
  end

  def parseit
    puts "PASSED PARAMS: #{params}"
    token = params[:token]
    Rails.logger.info "Year: #{Time.now.year}"
    Rails.logger.info "%%%%%%% ALL PARAMS : #{params}"
    resp = {'status': 200, 'message': 'GOT IT!', 'read':token}

    resp = get_instance_message

    render :json => resp, :status => 200
  end

  def slash_action
    Rails.logger.info "SELECTED_INSTANCE PARAMS : #{params.to_s}"
    # resp = {'status': 200, 'message': 'SELECTED!'}
    resp = handle_action(params)
    render :json => resp, :status => 200
  end
  
  private
    

end