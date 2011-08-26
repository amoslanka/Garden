module Garden
  module Mediators
    class Table
      
      def self.parse_table_name namish
        namish.parameterize.underscore
      end
      def self.get_instance table_name, id

        # puts "Find #{id} from #{table_name}"
        # puts id.class.to_s

        begin
          clazz = table_name.to_s.classify.constantize
          raise "Class #{clazz.to_s} is not an ActiveRecord subclass." unless clazz.new.is_a?(ActiveRecord::Base)
          instance = clazz.find id.to_s
          return instance
        rescue Exception => e
          puts "Could not find #{id} from table #{table_name}: #{e.message}"
          return nil
        end
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
        @relationships = []
        
        @headers.each do |header|
          @relationships.push header if @clazz.reflections.keys.include?(header.to_sym)
        end
      end
    
    
      def relationships
        @relationships
      end
      
      def create_instance attributes
        relationships = @relationships
        

        attributes = parse_row_relationships attributes, relationships

        instance = @clazz.new

        rejected = {}
        attributes.each_key do |key|
          rejected[key] = attributes.delete(key) if !instance.attributes.include?(key.to_s) && !relationships.include?(key.to_s)
        end

        instance.attributes = attributes

        # instance.id = rejected[:id] if rejected.key?(:id)

        # puts "Valid? #{instance.valid?}"
        # puts instance.errors.to_s

        valid = instance.valid?

        if instance.valid?
          instance.save!
          puts ".Saved instance: #{@clazz} #{instance.to_param}"
        else
          puts "Invalid instance."
          puts "#{@name}:"
          puts " - Valid attributes: #{attributes.keys}"
          puts " - Invalid attributes: #{rejected.keys}"
          puts " - Association attributes: #{relationships}"
          puts " - #{instance.errors}"
        end
      end
    
      def parse_row_relationships hash, relationships
        relationships.each do |r|
          # puts "Parsing row relationship: #{hash[r.to_sym]}"
          instance = get_instance r, hash[r.to_sym]
          hash[r.to_sym] = instance
        end
        hash
      end

    
    end
  end
end