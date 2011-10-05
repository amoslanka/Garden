
module Garden
  class Instance
    
    module Reflection
      # If an association method is passed in (f.input :author) try to find the
      # reflection object.
      def reflection_for(method) #:nodoc:
        if @object.class.respond_to?(:reflect_on_association)
          @object.class.reflect_on_association(method) 
        elsif @object.class.respond_to?(:associations) # MongoMapper uses the 'associations(method)' instead
          @object.class.associations(method) 
        end
      end

      def association_macro_for_method(method) #:nodoc:
        reflection = reflection_for(method)
        reflection.macro if reflection
      end

      def association_primary_key_for_method(method) #:nodoc:
        reflection = reflection_for(method)
        if reflection
          case association_macro_for_method(method)
          when :has_and_belongs_to_many, :has_many, :references_and_referenced_in_many, :references_many
            :"#{method.to_s.singularize}_ids"
          else
            return reflection.foreign_key.to_sym if reflection.respond_to?(:foreign_key)
            return reflection.options[:foreign_key].to_sym unless reflection.options[:foreign_key].blank?
            :"#{method}_id"
          end
        else
          method.to_sym
        end
      end
    end 
    module Columns
      # Get a column object for a specified attribute method - if possible.
      def column_for(method) #:nodoc:
        @object.column_for_attribute(method) if @object.respond_to?(:column_for_attribute)
      end
    end
    
    include Reflection
    include Columns
    
    def initialize(clazz, attributes=nil)
      @object = clazz.new
      assign_attributes attributes if attributes
    end
    
    def assign_attributes(attributes)
      
      attributes.each do |key, value|
        map_attribute key, value
      end
      


#        parse_row_relationships @object, attributes#, relationships

      # puts "A: #{attributes.keys}"

      # rejected = {}
      # attributes.each_key do |key|
      #   rejected[key] = attributes.delete(key) if !@object.attributes.include?(key.to_s)# && !relationships.include?(key.to_s)
      # end


#        attributes.delete_if do |key, value| !@object.attributes.include?(key.to_s) end

      # see https://github.com/justinfrench/formtastic/blob/master/lib/formtastic/helpers/input_helper.rb

#       @object.attributes = attributes

      # @object.id = rejected[:id] if rejected.key?(:id)


      if @object.valid?
        @object.save!
        
        # attributes.each do |key, value|
        #   if reflection = reflection_for(key)
        #     value.save!
        #   end
        # end

        
        
        puts ". Saved instance: #{@clazz} #{@object.to_param}"
      else
        puts "! Invalid instance: #{@object.to_param}"
        # puts "#{@name}:"
        # puts " - Valid attributes: #{attributes.keys}"
        # puts " - Excel sheet keys: #{all_keys}"
        # puts " - Invalid attributes: #{rejected.keys}"
        # puts " - Association attributes: #{relationships}"
        # puts "Attributes from excel: #{attributes}"
        # @object.errors.each do |error|
        #   puts "Error => #{error}: #{@object.errors.get error}"
        # end
        puts @object.errors.to_a
        puts "."
      end
    end

    def map_attribute(key, value)

      if reflection = reflection_for(key)
        # There is an assocation for this column.
        case reflection.macro
        when :has_many 
          parse_has_many(reflection, value)
        when :belongs_to 
          parse_belongs_to(reflection, value)
        when :has_one
          parse_has_one(reflection, value)
        end

        return

      end

      if column = column_for(key)

        case column.type

        # Special cases where the column type doesn't map to an input method.
        when :string

        when :integer

        when :float, :decimal

        when :timestamp
          # todo: parse a timestamp
        when :boolean
          value = ((value =~ /y|yes|true|t|1/i) || -1) >= 0
        end

        @object.send "#{key}=", value
        
        return
      end

      
      if @object.respond_to?(key.to_sym)
        puts "Ok. #{key}"
        @object.send "#{key}=", value
        return
      end

    end

    def parse_has_many r, value
      # puts " // Parsing #{r.name}, #{value}"
      ids = value.split(/\s*,\s*/)
      ids.each do |id|
        related_instance = get_real_instance r.class_name, id
        # puts ">> Creating a has-many relationship. #{id}, #{related_instance}"
        unless related_instance.nil?
          @object.send(r.name.to_sym) << related_instance
        end
      end
    end

    def parse_belongs_to r, value
      ri = get_real_instance(r, value)
      @object.attributes = { r.name.to_sym => ri }
      # puts "Parsing Belongs_To. #{@object.class} #{@object.to_param} --- #{r.name.to_sym} --- #{ri.class} #{ri.to_param}"
    end
    
    def parse_has_one r, value
      
      # puts "Parse has one.. #{value}, #{r.name.to_sym}, #{get_real_instance(r, value)}"
      
      related_instance = get_real_instance(r, value)
      @object.send("#{r.name}=".to_sym, related_instance)
    end
    
  end
  
  Instance.send :include, Helpers::RealInstance
  
end