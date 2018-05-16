class ColorMaster
  
  attr_reader :response
  
  def initialize(response)
    #@response = 
  #  binding.pry
     @product_id= response.id
     if !response.properties.find { |property| property.id == 'Class#' }.nil?
       @class= response.properties.find { |property| property.id == 'Class#' }['values'].first['id']
     end
     if !response.properties.find { |property| property.id == 'Dept#' }.nil?
       @dept= response.properties.find { |property| property.id == 'Dept#' }['values'].first['id']
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
         #binding.pry
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
    
    
  end


