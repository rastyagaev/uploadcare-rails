module Uploadcare
  module Rails
    module ActiveRecord
      def is_uploadcare_file attribute, options = {}
        options.symbolize_keys!
        opts = {
          autostore: true
        }.update options

        get_uuid = lambda do |attributes|
          re = /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/i
          m = re.match(attributes[attribute.to_s])
          if m.nil?
            nil
          else
            m[0]
          end
        end

        define_method "#{attribute}" do
          uuid = get_uuid.call(attributes)
          return nil unless uuid

          if instance_variable_defined?("@#{attribute}_cached")
            instance_variable_get("@#{attribute}_cached")
          else
            file_data = ::Rails.application.config.uploadcare.api.file(uuid)
            instance_variable_set("@#{attribute}_cached", file_data)
            file_data
          end
        end

        if opts[:autostore]
          after_save "store_#{attribute}"

          define_method "store_#{attribute}" do
            uuid = get_uuid.call(attributes)
             unless ::Rails.cache.exist?("uploadcare.file.#{uuid}.store")
              send(attribute).store
              ::Rails.cache.write("uploadcare.file.#{uuid}.store", true)
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.extend Uploadcare::Rails::ActiveRecord