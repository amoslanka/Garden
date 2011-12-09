require 'spreadsheet'
require 'csv'

module Garden
  module Spreadsheets
    
    class AbstractSpreadsheet
      def initialize filepath, options={}
        options ||= {}
        @options = options.reverse_merge! :some_option => "nevermind"
        open filepath
      end
    
      def open(filepath)
      end
      
      def build_mediator name
        validation = @options[:validate]
        validation = true if validation.nil?
        
        @mediator = Mediators::Table.new name, :validate => validation
        raise "Invalid mediator for table #{name}" unless @mediator.valid?
        @mediator.reference_by(@options[:reference]) if @options.has_key?(:reference)
        @mediator
      end
      
    end
    
    class Excel < AbstractSpreadsheet
    
      def open filepath
        message = "Planting excel spreadsheet: #{filepath}"
        message += " (only these worksheets: #{@options[:only].to_s})" if @options[:only]
        message += " (worksheet #{@options[:worksheet].to_s})" if @options[:worksheet]
        puts message
        
        excel_spreadsheet = ::Spreadsheet.open filepath
      
        worksheet_names = @options[:only] || @options[:worksheet] || excel_spreadsheet.worksheets.collect { |table| table.name }
        worksheet_names = [worksheet_names] unless worksheet_names.is_a?(Enumerable)

        # Import the worksheets
        worksheet_names.each do |name|
          puts "Parsing table #{name}"
          table = excel_spreadsheet.worksheets.find { |table| table.name == name.to_s }
          parse_worksheet table.name, table.to_a
        end
      
      end
      
      def parse_worksheet name, rows
        build_mediator name
        # Expects the first row to be the headers.
        headers = rows.shift.map { |header| header.to_s.strip.gsub(/ /, '-').underscore }
        rows.each do |row|
          attributes = parse_worksheet_attributes(headers, row)
          @mediator.row attributes
        end
      end
      
      def parse_worksheet_attributes keys, values
        h = {}
        keys.each_index do |index|
          key = keys[index].to_sym
          h[key] = values[index]
        end
        h
      end
      
    end
    
    class CSV < AbstractSpreadsheet
      def open filepath
        file = File.open filepath
        begin
          rows = ::CSV.parse(file, :headers => true)
        rescue Exception => e
          rows = []
        end
        
        # Build the mediator. Assume the table name is the same as the file's name passed in or the :table option
        table_name = @options.delete(:table) || File.basename(filepath, File.extname(filepath))
        message = "Planting csv spreadsheet: #{filepath}"
        message << " (into table #{table_name})"
        puts message
        build_mediator table_name
        
        rows.each do |row|
          attributes = row_to_attributes(row)
          @mediator.row attributes
        end
      end
      
      def row_to_attributes row
        h = {}
        row.each do |ary|
          key = ary.first.to_sym
          h[key] = ary.last
        end
        h
      end
      
    end
    
  end
end