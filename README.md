Garden
======

A utility for using different seed formats in your ActiveRecord 
database.

Some seeds need more hands touching them than just those of a 
developer. I prefer to allow large initial data sets to be 
populated by a production intern or someone who has time for 
the mundane while I continue a build out.


### Spreadsheets

Spreadsheets are always helpful, though they bring challenges 
with relationality. Column are automatically mapped to their 
matching attribute name.

When using Excel spreadsheets, each worksheet is automatically 
mapped to the db table using the same name.

##### Excel

    Garden.excel 'spreadsheetname'

##### CSV

    Garden.csv 'spreadsheetname'

#### Common options

- `:reference` The column name to use as a reference for updating values. Defaults to ID
- `:validate` A boolean, whether to perform validations on creation. Defaults to true.
- `:only` (Excel only) whitelist the worksheet names to seed
- `:worksheet` (Excel only) whitelist the single worksheet name to seed
- `:table` (CSV only) the table name to seed into (defaults to an interpretation based on the csv filename)

#### Callbacks
  
Callbacks allow for methods and actions to be injected in the 
process of the seeding of data. The most common callbacks are 
those that will be called on each instance that is created by 
the seed process.
  
###### before_validation

    before_validation :foo    

If arg is a method or Proc instance, it will be called with 
the record as the first argument. If arg is a symbol, Garden 
expects it refers to the name of a method for that instance and 
will call it on the record.
