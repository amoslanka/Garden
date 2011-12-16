module Garden
  class Models
    
    CALLBACKS = ActiveRecord::Callbacks::CALLBACKS
    
    
    def self.find namish, options={}
      
      # We return the found class if we've already found it.
      @@found ||= {}
      return @@found[namish.to_s] if @@found.has_key?(namish.to_s)
      
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
      
      if clazz
        apply_callbacks clazz, options
        @@found[namish.to_s] = clazz
      end
      clazz
      
    end
    
    def self.apply_callbacks clazz, callbacks
      @@created_callbacks ||= []
      
      for name in CALLBACKS do
        if callbacks.has_key?(name)
          callback = callbacks[name]
          
          # Will add a callback to the ActiveRecord model 
          clazz.send name, Proc.new{ |record| Garden::Models.execute_callback(record, callback) }
          
          # Retain a reference to the created callback so we can remove it later 
          key = name.to_s.gsub(/^(before|after|around)_/, '')
          list_name = "_#{key}_callbacks"
          callback_name = clazz.send(list_name).last.filter
          
          @@created_callbacks << { :class => clazz, :list => list_name, :callback => callback_name }
        end
      end

    end
    
    def self.execute_callback record, callback
      # puts "Executing callback on #{record.inspect}, #{callback}"
      
      case callback
      when Proc then callback.call(record)
      when Symbol, String then record.send(callback.to_sym)
      end
      
    end
    
    

  end
end
    