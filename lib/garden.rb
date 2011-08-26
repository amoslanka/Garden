require "garden/version"

module Garden

  autoload :Excel, 'garden/spreadsheets'
  autoload :Mediators, 'garden/mediators'

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
  
  def self.excel file_name_or_path
    filepath = resolve_file_path(file_name_or_path)
    Excel.new filepath
  end

  def self.resolve_file_path name_or_path
    File.exists?(name_or_path) ? name_or_path : File.join(Rails.root, "db/seeds/#{name_or_path}.xls")
  end

end
