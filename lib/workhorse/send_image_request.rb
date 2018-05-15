module Workhorse
  class SendImageRequest

    MAX_IDS_PER_CRUD = 100.freeze
    PROPERTY_NRF_COLOR_CODE = 'nrfColorCode'.freeze
    PROPERTY_COLOR_MASTER = 'Color Master?'.freeze
    PROPERTY_TURN_IN_DATE = 'Turn-In Date'.freeze

    def self.run
      new.run
    end

    def run
      products_to_send
      binding.pry
      # TODO: Iterate over products_to_send and generate xml
      # TODO: Send xml to workhorse
      # TODO: Mark sample requests as sent to workhorse
    end

    def products_to_send
      @products_to_send ||= unsent_sample_requests.group_by do |sample_req|
        sample_req.product_id
      end.map do |style_id, sample_reqs|

        # TODO: Doing individual calls here could result in exceeding the rate limit, maybe do in bulk instead!
        #       Perhaps use filter api instead, get skus where parent = style_id AND color is any of (provided colors) AND color master = true
        #       Perhaps also include turn in date or other criteria in filter instead of in code here

        # Use filter API like so: salsify.products_filtered_by(filter: "='My Property':'Some Value','Other Property':{'Any','Of','These','Values'}")

        product_family = retrieve_product_family(style_id)

        # For each color, find color master and see if it's ready for workhorse
        colors_requested = sample_reqs.map(&:color_id)
        result = product_family[:skus_by_color].map do |color, skus|
          next unless colors_requested.include?(color)
          color_master = skus.find { |sku| sku[PROPERTY_COLOR_MASTER] }
          binding.pry
          next unless ready_for_workhorse?(style, color_master)
          {
            style: style,
            color_master: color_master,
            skus: skus
          }
        end.compact
        binding.pry
        result
      end
    end

    def retrieve_product_family(style_id)
      style = salsify.product(style_id)
      sku_ids = salsify.product_relatives(style_id).children.map(&:id)
      skus_by_color = sku_ids.each_slice(MAX_IDS_PER_CRUD).map do |sku_id_batch|
        salsify.products(sku_id_batch)
      end.flatten.group_by do |sku|
        sku[PROPERTY_NRF_COLOR_CODE]
      end
      { style: style, skus_by_color: skus_by_color }
    end

    def ready_for_workhorse?(style, color_master)
      color_master[PROPERTY_TURN_IN_DATE]
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
