require 'spreadsheet'

module Garden
  module Spreadsheets
    class Excel
    
      def initialize filepath, options={}
        options ||= {}
        
        @options = options.reverse_merge! :some_option => "nevermind"
        
        open filepath
      end
    
      def open filepath
        message = "Planting spreadsheet: #{filepath}"
        message += " (only these worksheets: #{@options[:only].to_s})" if @options[:only]
        message += " (worksheet #{@options[:worksheet].to_s})" if @options[:worksheet]
        puts message
      
        @ss = Spreadsheet.open filepath
        worksheet_names = @options[:only] || @options[:worksheet] || @ss.worksheets.collect { |table| table.name }
        worksheet_names = [worksheet_names] unless worksheet_names.is_a?(Enumerable)

        # Import the worksheets
        worksheet_names.each do |name|
          puts "Parsing table #{name}"
          parse_table @ss.worksheets.find { |table| table.name == name.to_s }
        end
      
      end
    
      def parse_table table
        # The table object passed in is a Spreadsheet::Worksheet instance.

        table_mediator = Mediators::Table.new table.name
        if !table_mediator.valid?
          return
        end
      
        # Get the headers. These values will be the attribute names
        headers = table_mediator.parse_headers table.first.to_a
        
        # Set reference column if defined. 
        if @options.has_key?(:reference)
          table_mediator.reference_by(@options[:reference])
        end
      
        # Now loop the table rows, inserting records.
        table.each do |row|
          next if row.idx == 0
          table_mediator.create_instance parse_worksheet_row(headers, row)
        end
      end
    
      def parse_worksheet_row keys, values
        h = {}
        keys.each_index do |index|
          key = keys[index].to_sym
          h[key] = values[index]
        end
        h
      end
    end
  end
end