# frozen_string_literal: true

module Workhorse
  # transfer image request xml from Salsify to Workhorse
  class SendImageRequest
    # require 'net/sftp'
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

    @photo_requests
    @sample_requests
    @sample_request1
    @file_name
    def self.run
      new.run
    end

    def run
        photo_requests_to_send
      # TODO: Iterate over products_to_send and generate xml
       to_xml(@photo_requests)
      # TODO: Send xml to workhorse
      transfer_file
       # TODO: Mark sample requests as sent to workhorse
    end

    def photo_requests_to_send
      sample_req = SampleRequest.new
      @sample_requests = sample_req.getUnsentSampleRequest
      no_of_samples = @sample_requests.count
      sample_limit = 10
      puts "no of samples: #{no_of_samples}"
      $i=1
        while $i <= no_of_samples do
        range_end = ($i+sample_limit -1 < no_of_samples) ? $i+sample_limit-1 : no_of_samples
        getSalsifyData(@sample_requests[$i..range_end])
          $i +=sample_limit
        end
     end

     def getSalsifyData(samples)
      filter = '='
       @sample_requests.each do |sample_request|
        # TODO: need to limit the number of products else request may get fail
        # next unless color_master
        filter += "'Parent Product':'"
        filter += sample_request['product_id']
        filter += "','nrfColorCode':'"
        filter += sample_request['color_id'].strip
        filter += "','Color Master?':'true'="
       end
      filter.slice!(0, filter.length - 1)
      # binding.pry
      @photo_requests = retrieve_color_master(filter)
     end

     def transfer_file
      require 'net/sftp'
      Net::SFTP.start('belkuat.workhorsegroup.us', 'BLKUATUSER', password: '5ada833014a4c092012ed3f8f82aa0c1') do |sftp|
        # upload a file or directory to the remote host
         sftp.upload!(@file_name, File.join('SalsifyImportToWH', File.basename(@file_name)))
      end
    end

    def to_xml(photo_requests)
       @file_name = 'C:\tmp\photoRequests_' + Time.now.strftime('%Y-%m-%d_%H-%M-%S') + '.xml'
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.root do
          xml.Project do
            photo_requests.each do |photo_request|
              #    binding.pry
              color_master = ColorMaster.new(photo_request)
              #    color_master_heroku=ColorMasterHeroku.new(@sample_request1)
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
                             'Completion_Date' => (color_master.completion_date),
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
