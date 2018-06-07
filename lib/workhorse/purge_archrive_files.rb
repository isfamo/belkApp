module Workhorse
  class PurgeArchives
    attr_accessor :logger

    def initialize
      @logger = Logging::Log
    end

    def delete_workhorse_archvies
    end

    def delete_salsify_import_archvies
    end
  end
end
