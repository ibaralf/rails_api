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
    render :json => resp, :status => 200
  end
  

end
