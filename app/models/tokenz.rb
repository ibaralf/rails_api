require 'base64'

# Existing files must have tokens stored in Base64 encoding.
class Tokenz

  attr_accessor :circleci_token, :slack_token, :slashapp_token
  CIRCLECI_TOK_FILE = 'cci.txt'
  SLACK_TOK_FILE = 'slack.txt'
  SLASH_APP_TOK_FILE = 'slashapp.txt'
  
  def initialize()
    @circleci_token = read_token(CIRCLECI_TOK_FILE)
    @slack_token = read_token(SLACK_TOK_FILE)
    @slashapp_token = read_token(SLASH_APP_TOK_FILE)
  end

  def to_s
    puts "CCI: #{@circleci_token}"
    puts "SLACK: #{@slack_token}"
    puts "SLASHAPP: #{@slashapp_token}"
  end

  def self.get_circleci_token
    get_token(CIRCLECI_TOK_FILE)
  end

  def self.get_slack_token
    get_token(SLACK_TOK_FILE)
  end

  def self.get_slashapp_token
    get_token(SLASH_APP_TOK_FILE)
  end
  

  private

  def read_token(filename)
    full_path = File.dirname(__FILE__) + "/../../" + filename
    if File.file?(full_path)
      read_token = File.read(full_path)
      return Base64.strict_decode64(read_token.delete!("\n"))
    else
      Rails.logger.info "File does not exists: #{full_path}"
      return "XXXX"
    end
  end

  def self.get_token(filename)
    full_path = File.dirname(__FILE__) + "/../../" + filename
    if File.file?(full_path)
      read_token = File.read(full_path)
      return Base64.strict_decode64(read_token.delete!("\n"))
    else
      Rails.logger.info "File does not exists: #{full_path}"
      return "XXXX"
    end
  end
  
end
