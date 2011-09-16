module Garden
  module Mediators
    class Table
      
      def self.parse_table_name namish
        namish.parameterize.underscore
      end
      
      def initialize namish
        
        @name = Table.parse_table_name namish
        
        # Get the ActiveRecord model from the tablename.
        begin
          @clazz = @name.classify.constantize
          raise "Class #{@clazz.to_s} is not an ActiveRecord subclass." unless @clazz.new.is_a?(ActiveRecord::Base)
        rescue Exception => e
          puts " ** Could not derive ActiveRecord model from the provided name: #{namish}. Exception: #{e.message}"
        end
        
        @instance = @clazz.new
        
      end
      
      def valid?
        @clazz != nil
      end
    
      def parse_headers array
        @headers = array.map { |header| header.to_s.parameterize.underscore }
        # @relationships = []
        # 
        # @headers.each do |header|
        #   @relationships.push header if @clazz.reflections.keys.include?(header.to_sym)
        # end
      end
      
      # def relationships
      #   @relationships
      # end
      # 
      def create_instance attributes
        Instance.new @clazz, attributes
      end

    end
  end
end