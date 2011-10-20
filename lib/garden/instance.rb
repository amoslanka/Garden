
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
        # puts "Get column for #{method}"
        # puts "Found" if @object.respond_to?(:column_for_attribute) && @object.column_for_attribute(method)
        @object.column_for_attribute(method.to_s.strip) if @object.respond_to?(:column_for_attribute)
      end
    end
    
    include Reflection
    include Columns
    
    def initialize(clazz, attributes=nil, options={})
      @options = options.dup
      
      if @options.has_key? :reference
        @reference_column = @options.delete(:reference).to_sym
        @reference = attributes.delete @reference_column
        @object = clazz.send "find_by_#{@reference_column}".to_sym, @reference
        
        unless @object
          puts "Unable to find referenced instance using column '#{@reference_column}' and value '#{@reference}'"
          return
        end
      else
        @object = clazz.new
      end
      
      assign_attributes attributes if attributes
    end
    
    def assign_attributes(attributes)
      
      attributes.each do |key, value|
        # puts "assign attribute: #{key}, #{value}"
        map_attribute key, value
      end
      
      if @object.valid?
        @object.save!
        
        if @reference.nil?
          puts ". Saved new instance: #{@clazz} #{@object.to_param}"
        else
          puts ". Saved existing instance: #{@clazz} #{@object.to_param}"
        end
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
      return if value.nil?
      
      # puts "map_attribute: #{key} >> #{value}"
      

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
        
        # puts "Found column #{key}"

        case column.type

        # Special cases where the column type doesn't map to an input method.
        when :string
          value = value.to_s
        when :integer
          value = value.to_i
        when :float, :decimal

        when :timestamp
          # todo: parse a timestamp
        when :boolean
          value = ((value =~ /y|yes|true|t|1/i) || -1) >= 0
        end

        @object.send "#{key}=", value
        
        return
      end

      if key.to_s =~ /\./
        # Dealing with something like an interpolatable value. A property of an associated model.
        # puts "Interpolated association value!!" + " >> " + "@object.#{key} = #{value}"
        # puts "Assignment via eval"
        # puts "@object.#{key} = '#{value.gsub(/[']/, '\\\\\'')}'"
        assoc = key.to_s.split('.').first
        if @object.send(assoc.to_sym).nil?
          # build the association if it hasn't already been built.
          @object.send("build_#{assoc}".to_sym)
        end
        eval "@object.#{key} = '#{value.gsub(/[']/, '\\\\\'')}'"
        return
      end
      
      if @object.respond_to?(key.to_sym)
        # puts "Assignment via respond_to?"
        # puts "Directly setting. #{key}"
        @object.send "#{key}=", value
        return
      end

    end

    def parse_has_many r, value
      # puts " // Parsing #{r.name}, #{value}"
      ids = value.to_s.split(/\s*,\s*/)
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