
class SlircleController < ApplicationController
  before_action :token_authenticate

  include SlircleHelper

  # GET /slash
  def index
    ts = Time.now.strftime("%Y-%m-%d_%H:%M:%S")
    te = Time.zone.now.strftime("%Y-%m-%d_%H:%M:%S")
    resp = {'status': 200, 'message': "You\'re OK, it works. TS: #{ts}  ZONE: #{te}" }
    render :json => resp, :status => 200
  end

  # POST /slash
  def parseit
    resp = handle_slash_command(params)
    render :json => resp, :status => 200
  end

  # POST /slash_action
  def slash_action
    pload = JSON.parse(params[:payload])
    resp = handle_action(pload)
    render :json => resp, :status => 200
  end

end