require 'net/http'
require 'json'
require 'uri'
require_relative "../jobs/site_check_job"
require_relative "../models/tokenz"

#Background process that monitors thredup.com, posts to slack if down.

class ThredupMonitorController < ApplicationController
  before_action :token_authenticate

  include SlircleHelper

  # GET '/sitestat'
  def run_health_check()
    if ! SiteCheckJob.is_running?
      SiteCheckJob.create_run_file
      site_check_job = SiteCheckJob.new.async.perform("https://www.thredup.com/", false, true)
      resp = {'status': 200, 'message': 'Health check executed.'}
      render :json => resp, :status => 200
    else
      resp = {'status': 200, 'message': 'Health check currently running.'}
      render :json => resp, :status => 200
    end
  end

  # POST /sitestat?channel=channel_name
  def set_channel()
    user_channel = params[:channel_name]
    if user_channel
      @tokenz = Tokenz.new
      @tokenz.set_channel(user_channel)
      resp = {'status': 200, 'message': "Channel notifications configured to #{user_channel}."}
      render :json => resp, :status => 200
    else
      resp = {'status': 400, 'message': 'Channel must be specified.'}
      render :json => resp, :status => 400
    end
  end

end
