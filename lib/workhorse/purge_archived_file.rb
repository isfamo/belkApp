module WorkHorse
  require_relative '../utils/logging'
  require 'net/sftp'

  class PurgeArchivedFile
    attr_accessor :logger

    def initialize
      @logger = Utils::Log
    end

    def self.run
      new.run
    end

    def run
      delete_workhorse_archvies
    end

    def get_sftp_connection(server, username, password)
      @sftp = Net::SFTP.start(server, username, password)
    rescue Exception => e
      logger.debug(e.message)
    end

    # Delete the file older Rails.configuration.PURGE_DAYS_DIFF (60)  days
    def delete_workhorse_archvies
      get_sftp_connection(ENV.fetch('SALSIFY_BELK_HOST_SERVER'), ENV.fetch('SALSIFY_BELK_HOST_USERNAME'), :password => ENV.fetch('SALSIFY_BELK_HOST_PASSWORD'))
      puts @sftp
      @sftp.dir.glob(ENV.fetch('SALSIFY_WORKHORSE_FILE_LOC'), '*.zip').each do |file|
        file_name = file.name
        file_last_modify_time = file.attributes.attributes[:mtime]
        file_path = File.join(ENV.fetch('SALSIFY_WORKHORSE_FILE_LOC'), '/', file_name)
        time_diff = (Time.new.to_i - file_last_modify_time) / (86400)
        puts time_diff.to_i
        if time_diff.to_i > Rails.configuration.PURGE_DAYS_DIFF
          @sftp.remove!(file_path)
        end
      end
    end
  end
end
