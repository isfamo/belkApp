module Utils
  require 'mail'

  class SendMail
    def send_mail(from, to, subject, body, add_file: nil)
      mail = Mail.new
      # mail['from'] = from
      mail[:from] = from
      mail[:to] = to
      mail.subject = subject
      mail.body = body
      mail[:add_file] = add_file
      mail.delivery_method :smtp, address: 'belksmtp.belkinc.com', port: 25
      mail.deliver
    end
  end
end
