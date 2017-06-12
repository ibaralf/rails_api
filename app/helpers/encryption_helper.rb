require 'openssl'
require 'base64'

# Implementation to read encrypted Token.
# - 
class EncryptionHelper

  SALT = "Th1515My5altB4by"
  ALGORITHM = 'AES-128-CBC'

  def self.encrypt(msg)
    begin
      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.encrypt()
      cipher.key = SALT
      crypt = cipher.update(msg) + cipher.final()
      crypt_string = (Base64.strict_encode64(crypt))
      return crypt_string
    rescue Exception => exc
      Rails.logger.error ("EncryptionHelper encryption err message : exception caught")
      return "FAIL_AUTH"
    end
  end

  def self.decrypt(msg)
    begin
      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.decrypt()
      cipher.key = SALT
      tempkey = Base64.strict_decode64(msg)
      crypt = cipher.update(tempkey)
      crypt << cipher.final()
      return crypt
    rescue Exception => exc
      Rails.logger.error ("EncryptionHelper decryption err message : exception caught #{exc.message}")
      return "FAIL_AUTH"
    end
  end

end