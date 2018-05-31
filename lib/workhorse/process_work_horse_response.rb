module ProcessResponse
  require "nokogiri"
  require "net/sftp"
  require "archive/zip"
  require "logger"
  require "pry"
  require "salsify"

  class ProcessWorkHorseResponse
    LOCAL_DIR = File.join(Dir.pwd, "tmp/ftp/").freeze
    WORKHORSE_TO_SALSIFY = "/SalsifyImportToWH".freeze
    FILE_EXTN = "*.xml".freeze
    ARCHIVE_EXTN = ".zip".freeze
    attr_accessor :products, :logger, :listFiles, :zipFiles

    # Initialize the class attributes
    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG
      @products = Hash.new
      @zipFiles = []
      @listFiles = []
      salsify
    end

    def salsify
      #salsify
      #puts @salsify.respond_to?("default_response_handler")
      @salsify ||= Salsify::Client.create_with_token(
        ENV.fetch("SALSIFY_USER_EMAIL"),
        ENV.fetch("SALSIFY_API_TOKEN"),
        organization_id: ENV.fetch("SALSIFY_ORG_SYSTEM_ID"),
      )
    end

    ## Download the files from workhorse server to salsify server.
    def downloadRemotefiles
      logger.debug("DOWNLOADING FILES.")
      #sftp= Net::SFTP.start('belkuat.workhorsegroup.us', 'BLKUATUSER', :password => '5ada833014a4c092012ed3f8f82aa0c1')
      #ENV.fetch("WORKHORSE_HOST_SERVER"), ENV.fetch("WORKHORSE_HOST_USERNAME"), :password => ENV.fetch("WORKHORSE_HOST_PASSWORD")
      Net::SFTP.start(ENV.fetch("WORKHORSE_HOST_SERVER"), ENV.fetch("WORKHORSE_HOST_USERNAME"), :password => ENV.fetch("WORKHORSE_HOST_PASSWORD")) do |sftp|
        sftp.dir.glob(WORKHORSE_TO_SALSIFY, "*").each do |file|
          fileName = file.name
          sftp.download(File.join(WORKHORSE_TO_SALSIFY, "/", fileName), File.join(LOCAL_DIR, fileName))
          if File.extname(fileName).eql?(".zip")
            zipFiles.push(fileName)
          end
        end
      end
      logger.debug("FILES DOWNLOADED.")
    end

    ## Parse the xml on salsify server, placed by "readRemoteXML"  method.
    def parsePhotoRequestReponseXMl
      logger.debug("PARSING FILES.")
      Dir.glob(File.join(LOCAL_DIR, FILE_EXTN)).each do |file|
        begin
          doc = Nokogiri::XML.parse(File.open(file)) { |xml| xml.noblanks }
          project = doc.root.child
          project.children.each do |shotGrp|
            if shotGrp.name == "ShotGroup"
              puts shotGrp.name
              puts "SalsifyID: " + shotGrp["SalsifyID"]
              puts "ShotGroupStatus: " + shotGrp["ShotGroupStatus"]
              #products[shotGrp["SalsifyID"]] = shotGrp["ShotGroupStatus"]
            end
          end
        rescue Exception => e
          logger.debug("Error is processing file " + file + " " + e.message)
          next
        end
      end
      products
      logger.debug("PARSING COMPLETED.")
    end

    def unzipFiles
      logger.debug("UNZIPPING ZIP FILES.")
      if (!zipFiles.empty?)
        zipFiles.each do |fileName|
          Archive::Zip.extract(File.join(LOCAL_DIR, fileName), LOCAL_DIR)
        end
      end
      logger.debug("UNZIPPED ALL FILES.")
    end

    ## Archive the photo sample request xml files.
    def zipXMLFiles
      logger.debug("ZIPPING ALL FILES.")
      #time = Time.now.strftime("%Y-%d-%m_%H-%M-%S")
      Dir.glob(File.join(LOCAL_DIR, FILE_EXTN)).each {
        |file|
        listFiles.push(file)
      }
      puts listFiles.length
      listFiles.each {
        |file|
        if File.extname(file).eql?(".xml")
          Archive::Zip.archive((file + ARCHIVE_EXTN), file)
        end
      }
      listFiles.each {
        |file|
        File.delete(file)
      }
      logger.debug("ALL FILES ZIPPED.")
    end

    def updateProducts
      logger.debug("UPDATING THE PRODUCTS.")
      puts products
      logger.debug("PRODUCTS UPDATED.")
    end

    def uploadZipFiles
      logger.debug("UPLOADING ZIPPED FILES TO BELK FTP SERVER.")
      Net::SFTP.start(ENV.fetch("SALSIFY_BELK_HOST_SERVER"), ENV.fetch("SALSIFY_BELK_HOST_USERNAME"), :password => ENV.fetch("SALSIFY_BELK_HOST_PASSWORD")) do |sftp|
        listFiles.each.each do |file|
          fileName = file + ARCHIVE_EXTN
          sftp.upload((fileName), File.join(ENV.fetch("SALSIFY_WORKHORSE_FILE_LOC"), File.basename(fileName)))
        end
      end
      logger.debug("ALL FILES UPLOADED.")
    end

    def self.run
      new.run
    end

    ## Main method of the class, it calls all the utility methods of the calls in a sequential order
    def run
      logger.debug("WORK HORSE PROCESS JOB STARTED.")
      downloadRemotefiles
      unzipFiles
      #parsePhotoRequestReponseXMl
      #updateProducts
      zipXMLFiles
      uploadZipFiles
      logger.debug("JOB FINISHED.")
    end
  end
end
