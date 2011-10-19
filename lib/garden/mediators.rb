module Garden
  module Mediators
    class Table
      
      # def self.parse_table_name namish
      #   namish.parameterize.underscore
      # end
      
      def self.find_model_class namish
        clazz = nil
        namish = namish.singularize
        
        begin
          # try the format as it should be. Camelcase, and with :: or / for modules
          # Module::Classname
          clazz = namish.underscore.classify.constantize
        rescue
          begin
            # try the format "Class Name" by turning spaced words into camelcase
            clazz = namish.parameterize.underscore.classify.constantize
          rescue
            begin
              # try the format "Class Name" by turning spaced words into module separators
              clazz = namish.gsub(/ /, "/").underscore.classify.constantize
            rescue
              puts "Nope"
            end
          end
        end
        clazz
      end
      
      def initialize namish
        @instance_options ||= {}
        
        @clazz = Table.find_model_class namish
        
        if @clazz.nil? || !@clazz.new.is_a?(ActiveRecord::Base)
          puts "!! Class '#{namish}' could not be parsed to an ActiveRecord subclass."
        end
        
        # Get the ActiveRecord model from the tablename.
        # begin
        #   @clazz = @name.classify.constantize
        #   raise "Class #{@clazz.to_s} is not an ActiveRecord subclass." unless @clazz.new.is_a?(ActiveRecord::Base)
        # rescue Exception => e
        #   puts " ** Could not derive ActiveRecord model from the provided name: #{namish}. Exception: #{e.message}"
        # end
        
        @instance = @clazz.new
        
      end
      
      def valid?
        @clazz != nil
      end
    
      def parse_headers array
        # @headers = array.map { |header| header.to_s.parameterize.underscore }
        @headers = array.map { |header| header.to_s.underscore }
      end
      
      def reference_by col_name
        @instance_options[:reference] = col_name
      end
      
      # def relationships
      #   @relationships
      # end
      # 
      def create_instance attributes
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