module Workhorse
  class SendImageRequest

    MAX_IDS_PER_CRUD = 100.freeze
    PROPERTY_NRF_COLOR_CODE = 'nrfColorCode'.freeze
    PROPERTY_COLOR_MASTER = 'Color Master?'.freeze
    SELECTIONS = [
      'Vendor#',
      'vendorNumber',
      'Dept#',
      'Class#',
      'Turn-In Date',
      'ImageAssetSource'
    ].freeze

    def self.run
      new.run
    end

    def run
      photo_requests_to_send
      binding.pry
      # TODO: Iterate over products_to_send and generate xml
      # TODO: Send xml to workhorse
      # TODO: Mark sample requests as sent to workhorse
    end

    def photo_requests_to_send
      @photo_requests_to_send ||= unsent_sample_requests.group_by do |sample_request|
        sample_request.product_id
      end.map do |style_id, sample_request|
        color_master = retrieve_color_master(style_id, sample_request.first.color_id).try(:first)
        next unless color_master
        color_master = ColorMaster.new(color_master)
        next unless color_master.valid?
        color_master
      end.compact
    end

    def retrieve_color_master(style_id, nrf_color_code)
      salsify.products_filtered_by(
         filter: "='Parent Product':'#{style_id}','nrfColorCode':'#{nrf_color_code}','Color Master?':'true'",
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
