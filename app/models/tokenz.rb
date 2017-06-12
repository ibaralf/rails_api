require 'base64'
require 'yaml'
require_relative '../helpers/encryption_helper'

# Basic encryption of all token/URL based endpoints. 
# Don't hard code URL tokens or slack webhooks
# Simplifies storing/reading sensitive data
class Tokenz

  attr_accessor :circleci_token, :slack_token, :slashapp_token, :testing_chan_url, :shopdev_chan_url, :web_chan_url, :channel

  TOKENZ_FILE = 'kenzfile.yml'
  
  def initialize(tfile = TOKENZ_FILE)
    @yamlized_tokens = read_data(tfile)
    if @yamlized_tokens.any?
      load_vars
    else
      Rails.logger.info "Tokenz file #{tfile} returned empty"
    end
  end

  def load_vars
    @circleci_token = EncryptionHelper.decrypt(@yamlized_tokens[:circleci_token])
    @slack_token = EncryptionHelper.decrypt(@yamlized_tokens[:slack_token])
    @slashapp_token = EncryptionHelper.decrypt(@yamlized_tokens[:slashapp_token])
    @testing_chan_url = EncryptionHelper.decrypt(@yamlized_tokens[:testing_chan_url])
    @shopdev_chan_url = EncryptionHelper.decrypt(@yamlized_tokens[:shopdev_chan_url])
    @web_chan_url = EncryptionHelper.decrypt(@yamlized_tokens[:web_chan_url])
    @channel = EncryptionHelper.decrypt(@yamlized_tokens[:channel])
  end
  
  def to_s
    puts "CCI: #{@circleci_token}"
    puts "SLACK: #{@slack_token}"
    puts "SLASHAPP: #{@slashapp_token}"
    puts "TESTING_CHANNEL: #{@testing_chan_url}"
    puts "SHOPDEV_ CHANNEL: #{@shopdev_chan_url}"
    puts "WEB_ CHANNEL: #{@web_chan_url}"
  end

  def set_channel(chan_name)
    Rails.logger.info "Channel configured to #{chan_name}"
    @yamlized_tokens[:channel] = EncryptionHelper.encrypt(chan_name)
    save_data
  end

  
  ####################  STATIC METHODS TO GET TOKENS  ##################

  # Only used to initially generate the YAML file with needed data
  # NOTE: 
  def self.generate_tokenz_file(thash, fname)
    thash[:circleci_token] = EncryptionHelper.encrypt(thash[:circleci_token])
    thash[:slack_token] = EncryptionHelper.encrypt(thash[:slack_token])
    thash[:slashapp_token] = EncryptionHelper.encrypt(thash[:slashapp_token])
    thash[:testing_chan_url] = EncryptionHelper.encrypt(thash[:testing_chan_url])
    thash[:shopdev_chan_url] = EncryptionHelper.encrypt(thash[:shopdev_chan_url])
    thash[:web_chan_url] = EncryptionHelper.encrypt(thash[:shopdev_chan_url])
    thash[:channel] = EncryptionHelper.encrypt(thash[:channel])
    full_path = File.dirname(__FILE__) + "/../../" + fname
    Rails.logger.info "Generating file #{full_path} with #{thash}"
    File.write(full_path, thash.to_yaml)
  end
  
  def self.get_circleci_token
    EncryptionHelper.decrypt(get_data(TOKENZ_FILE)[:circleci_token])
  end

  def self.get_slack_token
    EncryptionHelper.decrypt(get_data(TOKENZ_FILE)[:slack_token])
  end

  def self.get_slashapp_token
    EncryptionHelper.decrypt(get_data(TOKENZ_FILE)[:slashapp_token])
  end

  def self.get_channel_url
    yml_data = get_data(TOKENZ_FILE)
    case EncryptionHelper.decrypt(yml_data[:channel])
    when 'shop_dev'
      EncryptionHelper.decrypt(yml_data[:shopdev_chan_url])
    when 'web'
      EncryptionHelper.decrypt(yml_data[:web_chan_url])
    else
      EncryptionHelper.decrypt(yml_data[:testing_chan_url])
    end
  end
  
  private

  def read_data(fname)
    @file_path = File.dirname(__FILE__) + "/../../" + fname
    if File.file?(@file_path)
      existing_yaml = YAML.load_file(@file_path)
      if existing_yaml
        return existing_yaml
      else
        return []
      end
    else
      Rails.logger.info "File does not exists: #{@file_path}"
      return []
    end
  end

  def save_data()
    File.write(@file_path, @yamlized_tokens.to_yaml)
  end

  def self.get_data(fname)
    full_path = File.dirname(__FILE__) + "/../../" + fname
    if File.file?(full_path)
      existing_yaml = YAML.load_file(full_path)
      if existing_yaml
        return existing_yaml
      else
        return []
      end
    else
      Rails.logger.info "File does not exists: #{full_path}"
      return []
    end
  end
  
  
end
