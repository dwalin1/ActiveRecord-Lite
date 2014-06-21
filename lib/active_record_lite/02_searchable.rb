require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    criteria = params.keys.map {|attr_name| "#{attr_name} = ?"}
    .join(" AND ")
    
    rows = DBConnection.execute(<<-SQL, *params.values)
    SELECT * 
    FROM #{table_name}
    WHERE #{criteria}
    SQL
    
    rows.map { |row| self.new(row) }
  end
end

class SQLObject
  extend Searchable
end

