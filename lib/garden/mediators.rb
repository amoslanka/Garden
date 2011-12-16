module Garden
  module Mediators
    class Table
      
      def initialize namish, options={}
        @instance_options = options.reverse_merge!({:validate => true})
        
        # puts "Instance options: #{@instance_options}"
        
        @clazz = Models.find namish, @instance_options
        
        if @clazz.nil? || !@clazz.new.is_a?(ActiveRecord::Base)
          puts "!! Class '#{namish}' could not be parsed to an ActiveRecord subclass."
        end
        
      end
      
      def valid?
        @clazz != nil
      end
      
      def reference_by col_name
        @instance_options[:reference] = col_name
      end
      
      def validate=(val)
        @instance_options[:validate] = val
      end

      def validate
        @instance_options[:validate]
      end
      
      def row attributes
        Instance.new @clazz, attributes, @instance_options.dup
      end

      def class_exists?(name)
        begin
          true if Kernel.const_get(name)
        rescue NameError
          false
        end
      end
   
    end
  end
end