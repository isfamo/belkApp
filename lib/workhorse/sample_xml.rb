# frozen_string_literal: true
module RRDonnelley
  class ProductPhotoRequests

    attr_reader :product_photo_requests

    def initialize(product_photo_requests)
      @product_photo_requests = product_photo_requests
    end

    def self.from_xml(child)
      new(child.children.select do |child|
        child.name.downcase == 'productphotorequest'
      end.map do |product_photo_request|
        ProductPhotoRequest.from_xml(product_photo_request)
      end)
    end

    def to_xml
      xml = Builder::XmlMarkup.new
      xml.tag!('productPhotoRequests') do |product_photo_requests_tag|
        product_photo_requests.each do |product_photo_request|
          product_photo_requests_tag << product_photo_request.to_xml
        end
      end
      xml.target!
    end

  end
end

module RRDonnelley
  class ProductPhotoRequest

    attr_reader :car, :product, :photos

    def initialize(car: nil, product: nil, photos: nil)
      @car = car
      @product = product
      @photos = photos
    end

    def self.from_xml(child)
      new(
        car: {
          'id' => child.children.find { |item|
            item.name.downcase == 'car'
          }.attributes['id'].value
        },
        product: Product.from_xml(child.children.find do |item|
          item.name.downcase == 'product'
        end),
        photos: child.children.find do |item|
          item.name.downcase == 'photos'
        end.children.reject do |item|
          item.is_a?(Nokogiri::XML::Text) && item.text.strip.empty?
        end.map do |photo|
          Photo.from_xml(photo)
        end
      )
    end

    def to_xml
      xml = Builder::XmlMarkup.new
      xml.tag!('productPhotoRequest') do |product_photo_request|
        product_photo_request.tag!('car', 'id' => car['id'])
        if product
          product_photo_request << product.to_xml
        end
        if photos && !photos.empty?
          product_photo_request.tag!('photos') do |photos_tag|
            photos.each do |photo|
              photos_tag << photo.to_xml
            end
          end
        end
      end
      xml.target!
    end

    class Product

      attr_reader :type, :name, :vendor, :style, :brand, :department, :_class

      def initialize(type: nil, name: nil, vendor: nil, style: nil, brand: nil, department: nil, _class: nil)
        @type = type
        @name = name
        @vendor = vendor
        @style = style
        @brand = brand
        @department = department
        @_class = _class
      end

      def self.from_xml(child)
        product_children = child.children.reject do |item|
          item.is_a?(Nokogiri::XML::Text) && item.text.strip.empty?
        end.each_with_object({}) do |item, hash|
          hash[item.name] = item
        end

        new(
          type: child.attributes['type'].value,
          name: product_children['name'].text,
          vendor: {
            'id' => product_children['vendor'].attributes['id'].value,
            'name' => product_children['vendor'].children.find { |item| item.name == 'name' }.text
          },
          style: {
            'id' => product_children['style'].attributes['id'].value
          },
          brand: {
            'name' => product_children['brand'].text
          },
          department: {
            'id' => product_children['department'].attributes['id'].value,
            'name' => product_children['department'].children.find { |item| item.name == 'name' }.text
          },
          _class: {
            'id' => product_children['class'].attributes['id'].value,
            'name' => product_children['class'].children.find { |item| item.name == 'name' }.text
          }
        )
      end

      def to_xml
        xml = Builder::XmlMarkup.new
        xml.tag!('product', {
          'type' => type
        }.reject { |_, val|
          val.nil? || val == ''
        }) do |product|
          product.tag!('name', name)
          product.tag!('vendor', 'id' => vendor['id']) do |vendor_tag|
            vendor_tag.tag!('name', vendor['name'])
          end
          product.tag!('style', 'id' => style['id'])
          product.tag!('brand', brand['name'])
          product.tag!('department', 'code' => department['id']) do |department_tag|
            department_tag.tag!('name', department['name'])
          end
          product.tag!('class', 'id' => _class['id']) do |class_tag|
            class_tag.tag!('name', _class['name'])
          end
        end
        xml.target!
      end

    end

    class Photo

      attr_reader :type, :file, :instructions, :samples

      def initialize(type: nil, file: nil, instructions: nil, samples: nil)
        @type = type
        @file = file
        @instructions = instructions
        @samples = samples
      end

      def self.from_xml(child)
        photo_children = child.children.reject do |item|
          item.is_a?(Nokogiri::XML::Text) && item.text.strip.empty?
        end.each_with_object({}) do |item, hash|
          if hash.include?(item.name)
            hash[item.name] = [hash[item.name], item].flatten
          else
            hash[item.name] = item
          end
        end

        new(
          type: child.attributes['type'].value,
          file: {
            'OForSLvalue' => photo_children['file'].children.find { |item|
              item.name.downcase == 'oforslvalue'
            },
            'name' => {
              'prefix' => photo_children['file'].children.find { |item|
                item.name == 'name'
              }.children.find { |item|
                item.name == 'prefix'
              }.children.first.text
            }
          },
          instructions: [photo_children['instructions']].flatten.compact.map { |item|
            item.children.first.text
          },
          samples: photo_children['samples'].children.reject { |item|
            item.is_a?(Nokogiri::XML::Text) && item.text.strip.empty?
          }.map { |sample|
            Sample.from_xml(sample)
          }
        )
      end

      def to_xml
        xml = Builder::XmlMarkup.new
        xml.tag!('photo', 'type' => type) do |photo|
          if file['name'] && file['name']['prefix'] && file['name']['prefix'] != ''
            photo.tag!('file') do |file_tag|
              file_tag.tag!('OForSLvalue', file['OForSLvalue'])
              file_tag.tag!('name') do |name_tag|
                name_tag.tag!('prefix', file['name']['prefix'])
              end
            end
          end
          if instructions && !instructions.empty?
            instructions.each do |instruction|
              photo.tag!('instructions', HTMLEntities.new.encode(instruction))
            end
          end
          if samples && !samples.empty?
            photo.tag!('samples') do |samples_tag|
              samples.each do |sample|
                samples_tag << sample.to_xml
              end
            end
          end
        end
        xml.target!
      end

      class Sample

        attr_reader :id, :type, :color, :return_requested, :return_information, :silhouette_required

        def initialize(id: nil, type: nil, color: nil, return_requested: nil, return_information: nil, silhouette_required: nil)
          @id = id
          @type = type
          @color = color
          @return_requested = return_requested
          @return_information = return_information
          @silhouette_required = silhouette_required
        end

        def self.from_xml(child)
          sample_children = child.children.reject do |item|
            item.is_a?(Nokogiri::XML::Text) && item.text.strip.empty?
          end.each_with_object({}) do |item, hash|
            hash[item.name] = item
          end

          new(
            id: child.attributes['id'].value,
            type: child.attributes['type'].value,
            color: {
              'code' => sample_children['color'].attributes['code'].value,
              'name' => sample_children['color'].children.find { |item| item.name == 'name' }.text
            },
            return_requested: sample_children['returnRequested'].text,
            return_information: {
              'shipping_account' => {
                'carrier' => sample_children['returnInformation'].children.find { |item|
                  item.name.downcase == 'shippingaccount'
                }.attributes['carrier'].value
              },
              'instructions' => sample_children['returnInformation'].children.select { |item|
                item.name.downcase == 'instructions'
              }.map { |item|
                item.children.first.text
              }
            },
            silhouette_required: sample_children['silhouetteRequired'].text
          )
        end

        def to_xml
          xml = Builder::XmlMarkup.new
          xml.tag!('sample', 'id' => id, 'type' => type) do |sample|
            if color && color['name'] && color['name'] != ''
              sample.tag!('color',
                {
                  'code' => color['code']
                }.reject { |_, val|
                  val.nil? || val == ''
                }) do |color_tag|
                color_tag.tag!('name', color['name'])
              end
            end
            if return_requested && return_requested != ''
              sample.tag!('returnRequested', return_requested)
            end
            sample.tag!('returnInformation') do |return_information_tag|
              return_information_tag.tag!('shippingAccount', 'carrier' => return_information['shipping_account']['carrier'])
              if return_information['instructions'] && !return_information['instructions'].empty?
                return_information['instructions'].each do |instruction|
                  return_information_tag.tag!('instructions', HTMLEntities.new.encode(instruction))
                end
              end
            end
            if silhouette_required && silhouette_required != ''
              sample.tag!('silhouetteRequired', silhouette_required)
            end
          end
          xml.target!
        end
      end
    end
  end
end
