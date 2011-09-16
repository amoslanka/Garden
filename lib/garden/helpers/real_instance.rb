module Garden
  module Helpers
    module RealInstance
      def get_real_instance(table, id)
        model_name = table.is_a?(ActiveRecord::Reflection::AssociationReflection) ? table.class_name : table.to_s.classify

        # puts "Find #{id} from #{table_name}"
        # puts id.class.to_s

        begin
          clazz = model_name.constantize
          raise "Class #{clazz.to_s} is not an ActiveRecord subclass." unless clazz.new.is_a?(ActiveRecord::Base)
          instance = clazz.find(id.to_s)

          # puts "!! Created clazz #{clazz.to_s} from model_name. No problem. #{instance.class.to_s} #{instance.to_param}"

          return instance
        rescue ActiveRecord::RecordNotFound => e

          instance = clazz.find_by_name(id.to_s) if instance.nil? && clazz.respond_to?(:find_by_name)
          # puts "++Find #{clazz.to_s} by title: #{id}" if instance.nil? && clazz.respond_to?(:find_by_title) 
          instance = clazz.find_by_title(id.to_s) if instance.nil? && clazz.respond_to?(:find_by_title) 
          # puts "++#{instance}" if instance
          return instance
        rescue Exception => e
          puts "Could not find #{id} from table #{model_name}: #{e.message}"
          return nil
        end
      
      end
    end
  end
end