require "garden/version"

module Garden
  extend ActiveSupport::Autoload
  
  autoload :Spreadsheets
  autoload :Mediators
  autoload :Helpers
  autoload :Instance
  
  # def self.plant 
  #   # todo
  # end
  # 
  # def self.all
  #   # todo
  # end
  # 
  # 
  # def self.spreadsheets 
  #   # todo
  # end
  
  def self.excel file_name_or_path, options=nil
    filepath = File.exists?(file_name_or_path) ? file_name_or_path : File.join(Rails.root, "db/seeds/#{file_name_or_path}.xls")
    Spreadsheets::Excel.new filepath, options
  end

  def self.csv file_name_or_path, options=nil
    filepath = File.exists?(file_name_or_path) ? file_name_or_path : File.join(Rails.root, "db/seeds/#{file_name_or_path}.csv")
    Spreadsheets::CSV.new filepath, options
  end


end
