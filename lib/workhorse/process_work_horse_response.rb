# frozen_string_literal: true

# module to process work horse response
module WorkHorse
  require 'nokogiri'
  require 'net/sftp'
  require 'archive/zip'
  require 'pry'
  require 'salsify'
  require_relative '../utils/logging'
  require_relative '../utils/SendEMail'
  require 'json'

  # class to process work horse response.
  class ProcessWorkHorseResponse
    include Amadeus::Import
    LOCAL_DIR = File.join(Dir.pwd, 'tmp/ftp/').freeze
    WORKHORSE_TO_SALSIFY = '/SalsifyExportFromWH'.freeze
    FILE_EXTN = '*.xml'.freeze
    ARCHIVE_EXTN = '.zip'.freeze
    attr_accessor :salsify_ids_map, :products_map, :logger, :list_files, :zip_files, :salsify_client, :json_import, :remote_workhorse_files

    # Initialize the class attributes
    def initialize
      @salsify_ids_map = Hash.new { |key, value| value = {} }
      @products_map = {}
      @zip_files = []
      @list_files = []
      @remote_workhorse_files = []
      @salsify_client = salsify
      @logger = Utils::Log
      @json_import ||= JsonImport.new
    end

    def self.run
      new.run
    end

    def salsify
      # puts @salsify.respond_to?('default_response_handler')
      salsify_client ||= Salsify::Client.create_with_token(
        Rails.configuration.SALSIFY_USER_EMAIL,
        Rails.configuration.SALSIFY_API_TOKEN,
        organization_id: Rails.configuration.SALSIFY_ORG_SYSTEM_ID
      )
      salsify_client
    end

    # Creates header for importing file in Salsify
    def add_header
      header = Header.new
      header.scope = []
      header.version = '2'
      json_import.add_header(header)
    end

    # Get the generic SFTP session object
    def get_sftp_connection(server, username, password)
      @sftp = Net::SFTP.start(server, username, password)
    rescue Exception => e
      logger.debug(e.message)
    end

    ## Download the files from workhorse server to salsify server. Delete the file from WorkHorse server after all the files are downloaded.
    def download_remotefiles
      logger.debug('DOWNLOADING FILES.')
      file_count = 0

      get_sftp_connection(Rails.configuration.WORKHORSE_HOST_SERVER, Rails.configuration.WORKHORSE_HOST_USERNAME, :password => Rails.configuration.WORKHORSE_HOST_PASSWORD)
      @sftp.dir.glob(WORKHORSE_TO_SALSIFY, '*').each do |file|
        begin
          file_name = file.name
          remote_file_path = File.join(WORKHORSE_TO_SALSIFY, '/', file_name)
          @sftp.download!(remote_file_path, File.join(LOCAL_DIR, file_name), :progress => CustomDownloadHandler.new)
          file_count += 1
          remote_workhorse_files.push(remote_file_path)
          zip_files.push(file_name) if File.extname(file_name).eql?('.zip')
        end
      rescue Exception => e
        logger.debug('Error is download file ' + e.message)
        next
      end
      logger.debug('FILES DOWNLOADED.')
      file_count
    end

    def delete_files_on_workhorse
      get_sftp_connection(Rails.configuration.WORKHORSE_HOST_SERVER, Rails.configuration.WORKHORSE_HOST_USERNAME, :password => Rails.configuration.WORKHORSE_HOST_PASSWORD)
      remote_workhorse_files.each do |delete_file|
        @sftp.remove!(delete_file)
      end
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
      logger.debug('PARSING COMPLETED.')
    end

    # parse and xml node and create a Hash to store the parsed xml data.
    def parse_xml(document)
      document.root.children.each do |project|
        project.children.each do |shotgrp|
          data = Hash.new
          salsify_ids_map[shotgrp['SalsifyID']] = data
          if shotgrp.name.eql? 'ShotGroup'
            data['Ecomm Photo Status'] = shotgrp['ShotGroupStatus']
            data['Image Specialist Task Status'] = 'Open' if shotgrp['ShotGroupStatus'].eql? 'Shots Selected'
            shotgrp.children.each do |image|
              if image.name.eql? 'Image'
                image.children.each do |sample|
                  data['Sample Reject Reason'] = sample['RejectReason'] if sample.name.eql? 'Sample'
                end
              end
            end
          end
        end
      end
    end

    # unzip the zip files download from Workhorse SFTP server
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
    def archive_files
      logger.debug('ZIPPING ALL FILES.')
      # time = Time.now.strftime('%Y-%d-%m_%H-%M-%S')
      file_extn = ['.xml', '.json']
      file_extn.each do |extension|
        Dir.glob(File.join(LOCAL_DIR, extension)).each do |file|
          list_files.push(file)
        end
      end
      puts list_files.length
      list_files.each do |file|
        if (File.extname(file).eql?('.xml') || File.extname(file).eql?('.json'))
          Archive::Zip.archive((file + ARCHIVE_EXTN), file)
        end
      end
      logger.debug('ALL FILES ZIPPED.')
    end

    # Make api call to Heroku app to Get the details for ecomm photo requests.
    def get_request_details
      logger.debug('UPDATING THE PRODUCTS.')
      salsify_ids_map.keys.each do |salsify_id|
        RestClient::Request.new(
          method: :get,
          url: Rails.configuration.HEROKU_API + '/' + salsify_id,
          headers: {:api_token => Rails.configuration.HEROKU_API_TOKEN}
        ).execute do |response, _request, _result|
          case response.code
          when 400
            @photo_response = JSON.parse(response.body)
          when 200
            @photo_response = JSON.parse(response.body)
          else
            logger.debug("Invalid response #{response.to_str} received.")
          end
          # Add each response data in the product_map accessor
          products_map["#{@photo_response['id']}"] = @photo_response['Requested_Color_Master_Sku']
        end
        #products_map['1512826'] = '0400109985350'
      end
      # nrfcolorCode = 'nrfColorCode'# colorMaster = 'Color Master? # product_id = 'product_id'# filterString ||= '='Parent Product':'1172567','Color Master?':'true''
      # response = salsifyClient.products_filtered_by(filter: filterString, selections: [product_id, colorMaster, nrfcolorCode], per_page: 250)
      logger.debug('PRODUCTS UPDATED.')
    end

    # Create json import for parsed xml file
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

    # Import the json file in Salsify
    def run_imports(file)
      logger.debug('STARTING SALSIFY IMPORT FOR WORKHORSE.')
      begin
        Salsify::Utils::Import.start_import_with_new_file(salsify_client, Rails.configuration.IMPORT_ID, file, wait_until_complete: false)
      rescue Exception => e
        logger.debug('Error while importing the salsify import file.' + e.message)
        raise Exception.new ('Error while importing the salsify import file.')
      end
      logger.debug('SALSIFY IMPORT FOR WORKHORSE COMPLETED.')
    end

    # Update the Heroku app DB with Rest API call.
    def update_workhorse_db
      logger.debug('UPDATING THE PRODUCTS.')
      RestClient::Request.new(
        method: :put,
        url: Rails.configuration.HEROKU_API,
        payload: get_json(salsify_ids_map),
        headers: {:api_token => Rails.configuration.HEROKU_API_TOKEN}
      ).execute do |response, _request, _result|
        case response.code
        when 400
          @photo_requests = JSON.parse(response.body)
        when 200
          @photo_requests = JSON.parse(response.body)
        else
          logger.debug("Invalid response #{response.to_str} received.")
        end
        # puts 'response =>  ' + response.body

      end
    end

    # Creates a json structure to update Heroku app DB, Takes input as a Hashes of response from WorkHorse to Salsify
    def get_json(map)
      product = Hash.new
      map.each do |key, value|
        sample = Hash.new
        sample['id'] = key.to_i
        sample['Ecomm_Photo_Status'] = value['Ecomm Photo Status']
        sample['Sample_Reject_Reason'] = value['Sample Reject Reason']
        sample['updated_at'] = Time.new
        product[key.to_i] = sample
      end
      Oj.dump({sample_requests: product.values}.as_json, mode: :compat, indent: 2)
    end

    # 1) Upload archives files on belk-salsify FTP location.
    # 2) Method will delete all the processed and archived files from tmp/ftp folder.
    def upload_delete_archive_files
      #time = Time.now.strftime('%Y-%d-%m_%H-%M-%S')
      logger.debug('UPLOADING ZIPPED FILES TO BELK FTP SERVER.')
      begin
        get_sftp_connection(Rails.configuration.SALSIFY_BELK_HOST_SERVER, Rails.configuration.SALSIFY_BELK_HOST_USERNAME, :password => Rails.configuration.SALSIFY_BELK_HOST_PASSWORD) do |sftp|
          list_files.each.each do |file|
            file_name = file + ARCHIVE_EXTN
            @sftp.upload(file_name, File.join(Rails.configuration.SALSIFY_WORKHORSE_FILE_LOC, File.basename(file_name)))
          end
        end
      rescue Exception => e
        logger.debug('Error while uploading files ' + e.backtrace.join("\n"))
      end

      Dir.glob(File.join(LOCAL_DIR, '*')).each do |file|
        File.delete(file)
      end
      logger.debug('ALL FILES UPLOADED.')
    end

    ## Main method of the class, it calls all the utility methods of the calls in a sequential order
    def run
      logger.debug('WORK HORSE PROCESS JOB STARTED.')
      file_count = 0
      file_count = download_remotefiles
      if file_count > 1
        unzip_files
        parse_photo_request_reponse_xml
        get_request_details
        import_response
        update_workhorse_db
        archive_files
        upload_delete_archive_files
        delete_files_on_workhorse
      else
        logger.debug('NO FILES TO BE PROCESSED.')
      end

      logger.debug('JOB FINISHED.')
    end
  end

  ## Download handler class
  class CustomDownloadHandler
    attr_accessor :logger

    def initialize
      @logger = Utils::Log
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
