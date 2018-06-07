module Logging
  require "logger"

  class Log
    @@dir = File.join(Dir.pwd, "log/belkApp.log")
    @@logs = Logger.new(@@dir, "daily", 7)    #STDOUT
    @@logs.level = Logger::DEBUG

    def self.debug(message)
      @@logs.debug(message)
    end
    def self.info(message)
      @@logs.info(message)
    end
    def self.error(message)
      @@logs.error(message)
    end
    private_class_method :new
  end
end
