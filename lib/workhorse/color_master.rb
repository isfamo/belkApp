# frozen_string_literal: true
class ColorMaster

  attr_reader :response

  def initialize(response)

    #@response =
  # binding.pry
     @product_id= response.id
     if !response.properties.find { |property| property.id == 'Class#' }.nil?
       @class= response.properties.find { |property| property.id == 'Class#' }['values'].first['id']
     end
     if !response.properties.find { |property| property.id == 'Dept#' }.nil?
       @dept_no= response.properties.find { |property| property.id == 'Dept#' }['values'].first['id']
     end
      if !response.properties.find { |property| property.id == 'ImageAssetSource' }.nil?
        @image_asset_source= response.properties.find { |property| property.id == 'ImageAssetSource' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'Turn-In Date' }.nil?
        @turn_in_date= response.properties.find { |property| property.id == 'Turn-In Date' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'Vendor#' }.nil?
        @vendor= response.properties.find { |property| property.id == 'Vendor#' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'fobNumber' }.nil?
        @fobNumber= response.properties.find { |property| property.id == 'fobNumber' }['values'].first['id']
      end

      if !response.properties.find { |property| property.id == 'deptName' }.nil?
        @deptName= response.properties.find { |property| property.id == 'deptName' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'Vendor  Name' }.nil?
        @vendor_name= response.properties.find { |property| property.id == 'Vendor  Name' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'Style#' }.nil?
        @style_no= response.properties.find { |property| property.id == 'Style#' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'Orin/Grouping #' }.nil?
        @orin= response.properties.find { |property| property.id == 'Orin/Grouping #' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'Product Name' }.nil?
        @prod_name= response.properties.find { |property| property.id == 'Product Name' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'pim_nrfColorCode' }.nil?
        @pim_color= response.properties.find { |property| property.id == 'pim_nrfColorCode' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'vendorColorDescription' }.nil?
        @vendor_color_desc= response.properties.find { |property| property.id == 'vendorColorDescription' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'Class#' }.nil?
        @class_no= response.properties.find { |property| property.id == 'Class#' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'Class_Desc' }.nil?
        @class_desc= response.properties.find { |property| property.id == 'Class_Desc' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'Completion Date' }.nil?
        @completion_date= response.properties.find { |property| property.id == 'Completion Date' }['values'].first['id']
      end
      if !response.properties.find { |property| property.id == 'nrfColorCode' }.nil?
        @nrf_color_code= response.properties.find { |property| property.id == 'nrfColorCode' }['values'].first['id']
      end
  end

  # # def attributes
  #   {
  #     product_id: @response.id,
  #      class: @response.properties.find { |property| property.id == 'Class#' }['values'].first['id'],
  #       dept: @response.properties.find { |property| property.id == 'Dept#' }['values'].first['id'],
  #       image_asset_source: @response.properties.find { |property| property.id == 'ImageAssetSource' }['values'].first['id'],
  #       turn_in_date: @response.properties.find { |property| property.id == 'Turn-In Date' }['values'].first['id'],
  #       vendor: @response.properties.find { |property| property.id == 'Vendor#' }['values'].first['id']
  #     }
  #   end
  #
  def product_id
    @product_id
  end
    def valid?
      turn_in_date? && sample_management?
    end

    def turn_in_date?
      @turn_in_date
    end

    def sample_management?
      @image_asset_source == 'Sample Management'
    end

    def dept_no
      @dept_no
    end

    def fobNumber
      @fobNumber
    end
    def vendor_No
      @vendor
    end
    def vendor_name
      @vendor_name
    end
    def dept_name
      @deptName
    end
    def style_no
      @style_no
    end
    def orin
      @orin
    end
    def prod_name
      @prod_name
    end
    def pim_color
      @pim_color
    end
    def vendor_color_desc
      @vendor_color_desc
    end
    def style_no
      @style_no
    end
    def class_no
      @class_no
    end
    def class_desc
      @class_desc
    end
    def nrf_color_code
      @nrf_color_code
    end
    def completion_date
      @completion_date
    end
  end
