# frozen_string_literal: true

# module to process work horse response
module ProcessResponse
  require 'nokogiri'
  require 'net/sftp'
  require 'archive/zip'
  require 'pry'
  require 'salsify'
  require 'logging'
  require 'csv'
  # class to process work horse response.
  class ProcessWorkHorseResponse
    include Amadeus::Import
    LOCAL_DIR = File.join(Dir.pwd, 'tmp/ftp/').freeze
    WORKHORSE_TO_SALSIFY = '/SalsifyExportFromWH'
    FILE_EXTN = '*.xml'
    ARCHIVE_EXTN = '.zip'
    IMPORT_ID = 402459
    attr_accessor :salsify_ids_map, :products_map, :logger, :list_files, :zip_files, :salsify_client, :json_import

    # Initialize the class attributes
    def initialize
      @salsify_ids_map = Hash.new { |key, value| value = {} }
      @products_map = {}
      @zip_files = []
      @list_files = []
      @salsify_client = salsify
      @logger = Logging::Log
      @json_import ||= JsonImport.new
    end

    def salsify
      # puts @salsify.respond_to?('default_response_handler')
      salsify_client ||= Salsify::Client.create_with_token(
        ENV.fetch('SALSIFY_USER_EMAIL'),
        ENV.fetch('SALSIFY_API_TOKEN'),
        organization_id: ENV.fetch('SALSIFY_ORG_SYSTEM_ID')
      )
      salsify_client
    end

    def add_header
      header = Header.new
      header.scope = []
      header.version = '2'
      json_import.add_header(header)
    end

    ## Download the files from workhorse server to salsify server.
    def download_remotefiles
      logger.debug('DOWNLOADING FILES.')
      # sftp= Net::SFTP.start('belkuat.workhorsegroup.us', 'BLKUATUSER', :password => '5ada833014a4c092012ed3f8f82aa0c1')
      # ENV.fetch('WORKHORSE_HOST_SERVER'), ENV.fetch('WORKHORSE_HOST_USERNAME'), :password => ENV.fetch('WORKHORSE_HOST_PASSWORD')
      begin
        Net::SFTP.start(ENV.fetch('WORKHORSE_HOST_SERVER'), ENV.fetch('WORKHORSE_HOST_USERNAME'), :password => ENV.fetch('WORKHORSE_HOST_PASSWORD')) do |sftp|
          sftp.dir.glob(WORKHORSE_TO_SALSIFY, '*').each do |file|
            file_name = file.name
            sftp.download!(File.join(WORKHORSE_TO_SALSIFY, '/', file_name), File.join(LOCAL_DIR, file_name), :progress => CustomDownloadHandler.new)
            zip_files.push(file_name) if File.extname(file_name).eql?('.zip')
          end
        end
      rescue Exception => e
        logger.debug('Error is download file ' + e.message)
      end

      logger.debug('FILES DOWNLOADED.')
    end

    ## Parse the xml on salsify server, placed by 'readRemoteXML'  method.
    def parse_photo_request_reponse_xml
      logger.debug('PARSING FILES.')
      Dir.glob(File.join(LOCAL_DIR, FILE_EXTN)).each do |file|
        begin
          doc = Nokogiri::XML.parse(File.open(file)) { |xml| xml.noblanks }
          parse_xml(doc)
        rescue StandardError? => e
          logger.debug('Error is processing file ' + file + ' ' + e.message)
          next
        end
      end
      puts salsify_ids_map
      logger.debug('PARSING COMPLETED.')
    end

    def parse_xml(document)
      document.root.children.each do |project|
        project.children.each do |shotgrp|
          data = Hash.new
          salsify_ids_map[shotgrp['SalsifyID']] = data
          if shotgrp.name == 'ShotGroup'
            data['Ecomm Photo Status'] = shotgrp['ShotGroupStatus']
            data['Image Specialist Task Status'] = 'Open' if shotgrp['ShotGroupStatus'] == 'Shot Selected'
            shotgrp.children.each do |image|
              if image.name = 'Image'
                image.children.each do |sample|
                  data['Sample Reject Reason'] = sample['RejectReason'] if sample.name = 'Sample'
                end
              end
            end
          end
        end
      end
    end

    def unzip_files
      logger.debug('UNZIPPING ZIP FILES.')
      if !zip_files.empty?
        zip_files.each do |file_name|
          Archive::Zip.extract(File.join(LOCAL_DIR, file_name), LOCAL_DIR)
        end
      end
      logger.debug('UNZIPPED ALL FILES.')
    end

    ## Archive the photo sample request xml files.
    def zip_xml_files
      logger.debug('ZIPPING ALL FILES.')
      # time = Time.now.strftime('%Y-%d-%m_%H-%M-%S')
      Dir.glob(File.join(LOCAL_DIR, FILE_EXTN)).each do |file|
        list_files.push(file)
      end
      puts list_files.length
      list_files.each do |file|
        Archive::Zip.archive((file + ARCHIVE_EXTN), file) if File.extname(file).eql?('.xml')
      end
      list_files.each do |file|
        File.delete(file)
      end
      logger.debug('ALL FILES ZIPPED.')
    end

    def update_products
      logger.debug('UPDATING THE PRODUCTS.')
      # salsify_ids_map.keys.each_slice(1)
      RestClient::Request.new(
        method: :get,
        url: 'https://customer-belk-qa.herokuapp.com/api/workhorse/sample_requests?unsent=true',
        headers: {:api_token => '4591D7EF39D6CFE0482778AACB8A0534B99DB31317D528E310373B1BC0E16E22'}
      ).execute do |response, _request, _result|
        case response.code
        when 400
          @photo_requests = JSON.parse(response.body)
        when 200
          @photo_requests = JSON.parse(response.body)
        else
          #logger.debug("Invalid response #{response.to_str} received.")
        end
        # puts 'response =>  ' + response.body
        @photo_requests.each do |req|
          #products_map["#{req['id']}"] = req['product_id']
          products_map['1512826'] = '0400109985350'
        end
      end
      # nrfcolorCode = 'nrfColorCode'# colorMaster = 'Color Master? # product_id = 'product_id'# filterString ||= '='Parent Product':'1172567','Color Master?':'true''
      # response = salsifyClient.products_filtered_by(filter: filterString, selections: [product_id, colorMaster, nrfcolorCode], per_page: 250)
      logger.debug('PRODUCTS UPDATED.')
    end

    def import_response
      salsify_ids_map.each do |id, value|
        product_data = {'product_id' => products_map[id]}
        product_data = product_data.merge(value)
        json_import.products[id] = product_data
      end
      add_header
      file = File.join(LOCAL_DIR, 'workhorse_update.json')
      File.open(file, 'w') { |json_file| json_file.write(json_import.serialize) }
      run_import(file)
    end

    def run_imports(file)
      response = Salsify::Utils::Import.start_import_with_new_file(salsify_client, IMPORT_ID, file, wait_until_complete: false)
      puts response
    end

    def upload_zip_files
      #time = Time.now.strftime('%Y-%d-%m_%H-%M-%S')
      logger.debug('UPLOADING ZIPPED FILES TO BELK FTP SERVER.')
      begin
        Net::SFTP.start(ENV.fetch('SALSIFY_BELK_HOST_SERVER'), ENV.fetch('SALSIFY_BELK_HOST_USERNAME'), :password => ENV.fetch('SALSIFY_BELK_HOST_PASSWORD')) do |sftp|
          list_files.each.each do |file|
            file_name = file + ARCHIVE_EXTN
            sftp.upload(file_name, File.join(ENV.fetch('SALSIFY_WORKHORSE_FILE_LOC'), File.basename(file_name)))
          end
        end
      rescue Exception => e
        logger.debug('Error is processing file ' + e.message)
      end
      logger.debug('ALL FILES UPLOADED.')
    end

    def self.run
      new.run
    end

    ## Main method of the class, it calls all the utility methods of the calls in a sequential order
    def run
      logger.debug('WORK HORSE PROCESS JOB STARTED.')
      download_remotefiles
      unzip_files
      parse_photo_request_reponse_xml
      update_products
      zip_xml_files
      upload_zip_files
      import_response
      logger.debug('JOB FINISHED.')
    end
  end

  ## Download handler class
  class CustomDownloadHandler
    attr_accessor :logger

    def initialize
      @logger = Logging::Log
    end

    def on_open(_downloader, file)
      logger.debug('starting download: #{file.remote} -> #{file.local} (#{file.size} bytes)')
    end

    def on_get(_downloader, file, offset, data)
      logger.debug('writing #{data.length} bytes to #{file.local} starting at #{offset}')
    end

    def on_close(_downloader, file)
      logger.debug('finished with #{file.remote}')
    end

    def on_mkdir(_downloader, path)
      logger.debug('creating directory #{path}')
    end

    def on_finish(_downloader)
      logger.debug ('all done!')
    end
  end
end
