# frozen_string_literal: true
module Workhorse
  class SendImageRequest
    # require 'net/sftp'
    MAX_IDS_PER_CRUD = 100.freeze
    PROPERTY_NRF_COLOR_CODE = 'nrfColorCode'.freeze
    PROPERTY_COLOR_MASTER = 'Color Master?'.freeze
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

    @photoRequests
    @sample_requests
    @sample_request1
    @fileName
    def self.run
      new.run
    end

    def run

      #binding.pry
      photo_requests_to_send
      # TODO: Iterate over products_to_send and generate xml
      #binding.pry
      to_xml(@photoRequests)
      # TODO: Send xml to workhorse
      transferFile
      #binding.pry
      # TODO: Mark sample requests as sent to workhorse
    end


    def photo_requests_to_send
  #    smapleRequests = []
      sampleReq = SampleRequest.new
    @sample_requests = sampleReq.getUnsentSampleRequest
      filter="="
    #  binding.pry
              @sample_requests.each  do |sample_request|
                # TODO need to limit the number of products else request may get fail
                 #next unless color_master
              filter+="'Parent Product':'"
              filter+= sample_request["product_id"]
              filter+="','nrfColorCode':'"
              filter+=sample_request["color_id"].strip
              filter+="','Color Master?':'true'="
              @sample_request1 = sample_request
          end
            #  binding.pry
          filter.slice!(0,filter.length-1)
        # binding.pry
          @photoRequests = retrieve_color_master(filter)

      #  puts(@photoRequests)

    end
    # def formatFilterRequest
    #
    # end
    def transferFile
      require 'net/sftp'
      Net::SFTP.start('belkuat.workhorsegroup.us', 'BLKUATUSER', :password => '5ada833014a4c092012ed3f8f82aa0c1') do |sftp|
       # upload a file or directory to the remote host
       #binding.pry
      sftp.upload!(@fileName, File.join('SalsifyImportToWH',File.basename(@fileName)))

    end
    end

    def to_xml(photoRequests)
    ##  puts(attributes.dept)
      @fileName = 'C:\tmp\photoRequests_'+Time.now.strftime('%Y-%m-%d_%H-%M-%S')+'.xml'
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.root {
          xml.Project {
            photoRequests.each do |photo_request|
          #    binding.pry
            color_master=ColorMaster.new(photo_request)
        #    color_master_heroku=ColorMasterHeroku.new(@sample_request1)
            xml.ShotGroup('SalsifyID' =>'') {
              xml.Image('ImageName' => "#{color_master.vendor_No}_#{color_master.style_no}_A_#{color_master.nrf_color_code}",'ShotView' => 'A','ShotType' =>"",'Collections' => 'N','BuyerComments' => ''){
               xml.Sample('FOB' => color_master.fobNumber,'Deptt_Nmbr' => color_master.dept_no, 'Deptt_Nm' => color_master.dept_name ,
                          'Vndr_Nm' => color_master.vendor_name ,'Vndr_ID' =>color_master.vendor_No ,'Style_Nmbr' =>color_master.style_no ,
                          'Style_ORIN' => color_master.orin ,'Prod_Nm'  => color_master.prod_name ,'Color_Nmbr' => color_master.pim_color ,
                          'Color_Nm'  => color_master.vendor_color_desc, 'Class_Nmbr' =>color_master.class_no,'Class_Desc' =>color_master.class_desc,
                          'Completion_Date' =>color_master.completion_date,'Prod_cd_Salsify' => color_master.product_id ,'ECOMColorCd' => color_master.nrf_color_code,
                          'ReturnTo' => '','RequestedReturnDt' =>'','ReturnNotes' => ''

                  ){



                }
              }
            }
          end
          }
        }
      end
      #binding.pry
      File.write(@fileName, builder.to_xml)
      puts builder.to_xml
    end

    def retrieve_color_master(filter)
      salsify.products_filtered_by(
        filter: filter,
        selections: SELECTIONS
      ).products
    end

    def unsent_sample_requests
      @unsent_sample_requests ||= [
        SampleRequest.where(sent_to_workhorse: false),
        SampleRequest.where(sent_to_workhorse: nil)
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
