module Garden
  module Mediators
    class Table
      
      def self.parse_table_name namish
        namish.parameterize.underscore
      end
      def self.get_instance table, id

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
        # relationships = @relationships
        
        all_keys = attributes.keys

        instance = @clazz.new
        parse_row_relationships instance, attributes#, relationships

        # puts "A: #{attributes.keys}"

        # rejected = {}
        # attributes.each_key do |key|
        #   rejected[key] = attributes.delete(key) if !instance.attributes.include?(key.to_s)# && !relationships.include?(key.to_s)
        # end

        
        attributes.delete_if do |key, value| !instance.attributes.include?(key.to_s) end
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
          puts " - Excel sheet keys: #{all_keys}"
          # puts " - Invalid attributes: #{rejected.keys}"
          # puts " - Association attributes: #{relationships}"
          instance.errors.each do |error|
            puts error
          end
        end
      end
    
      def parse_row_relationships instance, hash#, relationships
        @clazz.reflections.each_value do |r|
          next unless hash.has_key?(r.name)
          # Remove the value from the hash.
          value = hash.delete(r.name.to_sym)
          case r.macro
          when :has_many 
            parse_has_many(instance, r, value)
          when :belongs_to 
            parse_belongs_to(instance, r, value)
          end
        end
        
        # relationships.each do |r|
        #   # puts "Parsing row relationship: #{hash[r.to_sym]}"
        #   instance = get_instance r, hash[r.to_sym]
        #   hash[r.to_sym] = instance
        # end
        # hash
      end
      
      
      def parse_has_many instance, r, value
        # puts " // Parsing #{r.name}, #{value}"
        ids = value.split(/\s*,\s*/)
        ids.each do |id|
          related_instance = Table.get_instance r.class_name, id
          # puts ">> Creating a has-many relationship. #{id}, #{related_instance}"
          unless related_instance.nil?
            instance.send(r.name.to_sym) << related_instance
          end
        end
      end
    
      def parse_belongs_to instance, r, value
        ri = Table.get_instance(r, value)
        instance.attributes = { r.name.to_sym => ri }
        
        # puts "Parsing Belongs_To. #{instance.class} #{instance.to_param} --- #{r.name.to_sym} --- #{ri.class} #{ri.to_param}"
      end
    
    end
  end
end