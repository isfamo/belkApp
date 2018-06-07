# frozen_string_literal: true

require 'logger'
require 'net/sftp'
require 'time'

module Workhorse
  # transfer image request xml from Salsify to Workhorse
  class SendImageRequest
    attr_accessor :logger
    MAX_IDS_PER_CRUD = 100
    SELECTIONS = [
      'Vendor#',
      'vendorNumber',
      'Dept#',
      'Class#',
      'Turn-In Date',
      'ImageAssetSource',
      'fobNumber',
      'deptName',
      'Vendor  Name',
      'Style#',
      'Orin/Grouping #',
      'Product Name',
      'pim_nrfColorCode',
      'vendorColorDescription',
      'Class Description',
      'Completion Date',
      'product_id',
      'nrfColorCode'
    ].freeze
    def initialize
      @logger = Logging::Log
    end
    @photo_requests
    @sample_requests
    @sample_request1
    @file_name
    def self.run
      new.run
    end

    def run
      logger.info('***** Image request job has started *****')
      photo_requests_to_send
      # Iterate over products_to_send and generate xml
      to_xml(@photo_requests)
      #  Send xml to workhorse
      transfer_file
      # TODO: Mark sample requests as sent to workhorse
      # Archive the files to salsify ftp
      archive_file
      logger.info('***** Image request job completed *****')
    end

    def photo_requests_to_send
      logger.debug('Collecting Samples data... ')
      sample_req = SampleRequest.new
      @sample_requests = sample_req.get_unsent_sample_request
      no_of_samples = @sample_requests.count
      sample_limit = 10
      logger.info("no of samples: #{no_of_samples}")
      logger.debug('Get data from salsify... ')
      $i = 1
      while $i <= no_of_samples
        range_end = $i + sample_limit - 1 < no_of_samples ? $i + sample_limit - 1 : no_of_samples
        get_salsify_data(@sample_requests[$i..range_end])
        $i += sample_limit
      end
     end

    def get_salsify_data(_samples)
      filter = '='
      @sample_requests.each do |sample_request|
        filter += "'Parent Product':'"
        filter += sample_request['product_id']
        filter += "','nrfColorCode':'"
        filter += sample_request['color_id'].strip
        filter += "','Color Master?':'true'="
      end
      filter.slice!(0, filter.length - 1)

      @photo_requests = retrieve_color_master(filter)
    end

    def transfer_file
      begin
        Net::SFTP.start(ENV.fetch('WORKHORSE_HOST_SERVER'), ENV.fetch('WORKHORSE_HOST_USERNAME'), password: ENV.fetch('WORKHORSE_HOST_PASSWORD')) do |sftp|
          logger.debug('SFTP connection created')
          # upload  file to the remote host
          sftp.upload!(@file_name, File.join('SalsifyImportToWH', File.basename(@file_name)))
        end
      rescue Exception => e
        logger.debug('Error while copying the feed file to workhorse' + e.message)
      end
      logger.info('File transfer completed')
   end

    def archive_file
      begin
        Net::SFTP.start(ENV.fetch('SALSIFY_BELK_HOST_SERVER'), ENV.fetch('SALSIFY_BELK_HOST_USERNAME'), password: ENV.fetch('SALSIFY_BELK_HOST_PASSWORD')) do |sftp|
          logger.debug('SFTP connection created')
          sftp.upload!(@file_name, File.join(ENV.fetch('PHOTO_REQUEST_ARCHIVE_LOC'), File.basename(@file_name)))
        end
      rescue Exception => e
        logger.debug('Error while copying the feed file to salsify ftp' + e.message)
      end
      logger.info('File archiving completed')
   end

    def to_xml(photo_requests)
      @file_name = 'C:\tmp\photoRequests_' + Time.now.strftime('%Y-%m-%d_%H-%M-%S') + '.xml'
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.root do
          xml.Project do
            photo_requests.each do |photo_request|
              color_master = ColorMaster.new(photo_request)

              xml.ShotGroup('SalsifyID' => '') do
                xml.Image(
                  'ImageName' => "#{color_master.vendor_No}_#{color_master.style_no}_A_#{color_master.nrf_color_code}",
                  'ShotView' => 'A',
                  'ShotType' => '',
                  'Collections' => 'N',
                  'BuyerComments' => ''
                ) do
                  xml.Sample('FOB' => color_master.fobNumber,
                             'Deptt_Nmbr' => color_master.dept_no,
                             'Deptt_Nm' => color_master.dept_name,
                             'Vndr_Nm' => color_master.vendor_name,
                             'Vndr_ID' => color_master.vendor_No,
                             'Style_Nmbr' => color_master.style_no,
                             'Style_ORIN' => color_master.orin,
                             'Prod_Nm' => color_master.prod_name,
                             'Color_Nmbr' => color_master.pim_color,
                             'Color_Nm' => color_master.vendor_color_desc,
                             'Class_Nmbr' => color_master.class_no,
                             'Class_Desc' => color_master.class_desc,
                             'Completion_Date' => color_master.completion_date,
                             'Prod_cd_Salsify' => color_master.product_id,
                             'ECOMColorCd' => color_master.nrf_color_code,
                             'ReturnTo' => '',
                             'RequestedReturnDt' => '',
                             'ReturnNotes' => '') do
                  end
                end
              end
            end
          end
        end
      end
      File.write(@file_name, builder.to_xml)
     rescue Exception => e
       logger.error('Exception while building the xml: ' + e.message)
     end

    def retrieve_color_master(filter)
      salsify.products_filtered_by(
        filter: filter,
        selections: SELECTIONS
      ).products
    end

    def unsent_sample_requests
      @unsent_sample_requests ||= [
        sample_request.where(sent_to_workhorse: false),
        sample_request.where(sent_to_workhorse: nil)
      ].flatten
    end

    def salsify
      @salsify ||= Salsify::Client.create_with_token(
        ENV.fetch('SALSIFY_USER_EMAIL'),
        ENV.fetch('SALSIFY_API_TOKEN'),
        organization_id: ENV.fetch('SALSIFY_ORG_SYSTEM_ID')
      )
    end
  end
end
