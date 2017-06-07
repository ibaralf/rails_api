
class SlircleController < ApplicationController
  include SlircleHelper

  # GET /slash
  def index
    resp = {'status': 200, 'message': 'You\'re OK, it works.'}
    render :json => resp, :status => 200
    #json_response(resp)
  end

  # POST /slash
  def parseit
    puts "PASSED PARAMS: #{params}"
    token = params[:token]
    Rails.logger.info "%%%%%%% ALL PARAMS : #{params}"
    #resp = {'status': 200, 'message': 'GOT IT!', 'read':token}
    resp = handle_slash_command(params)
    render :json => resp, :status => 200
  end

  # POST /slash_action
  def slash_action
    Rails.logger.info "SELECTED_INSTANCE PARAMS : #{params}"
    allp = JSON.parse(params[:payload])
    puts "PAYLOAD: #{allp}"
#    Rails.logger.info "ALL PARM : #{allp.to_s}"
    # resp = {'status': 200, 'message': 'SELECTED!'}
    resp = handle_action(allp)
    render :json => resp, :status => 200
  end
  
  private
    

end