class ColorMaster
  
  attr_reader :response
  
  def initialize(response)
    @response = response
    
  end
  
  def attributes
    {
      product_id: @response.id,
       class: @response.properties.find { |property| property.id == 'Class#' }['values'].first['id'],
        dept: @response.properties.find { |property| property.id == 'Dept#' }['values'].first['id'],
        image_asset_source: @response.properties.find { |property| property.id == 'ImageAssetSource' }['values'].first['id'],
        turn_in_date: @response.properties.find { |property| property.id == 'Turn-In Date' }['values'].first['id'],
        vendor: @response.properties.find { |property| property.id == 'Vendor#' }['values'].first['id']
      }
    end
    
    def valid?
      turn_in_date? && sample_management?
    end
    
    def turn_in_date?
      attributes[:turn_in_date]
    end
    
    def sample_management?
      attributes[:image_asset_source] == 'Sample Management'
    end
    
    def to_xml
    ##  puts(attributes.dept)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.root {
          xml.Project {
            xml.ShotGroup('id' => @response.id, 'CollectionOrGroup' => 'N', 'SalsifyID' => '12345') {
              xml.Image('id' => @response.id){
               xml.Sample('deptnnum' => @response.id ){
                  xml.id_ "10"   
                }
              }
            }
          }
        }
      end
      puts builder.to_xml
    end
  end
  end

