require_relative 'db_connection'
require 'active_support/inflector'
require 'debugger'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  
  def self.columns
    column_strings = DBConnection.execute2("SELECT * FROM #{table_name}").first
    column_symbols = column_strings.map {|column_name| column_name.to_sym }
    
    column_strings.each_index do |i|
      define_method column_strings[i] do
        @attributes[column_symbols[i]]
      end
       
      define_method "#{column_strings[i]}=" do | new_value |
        @attributes[column_symbols[i]] = new_value
      end
    end
    
    column_symbols
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    parse_all(DBConnection.execute("SELECT #{table_name}.* FROM #{table_name}"))
  end
  
  def self.parse_all(results)
    results.map {|row| self.new(row)}
  end

  def self.find(id)
    row = DBConnection.execute(<<-SQL, id)
    SELECT #{table_name}.* 
    FROM #{table_name} 
    WHERE #{table_name}.id = ?
    SQL
    
    self.new(row.first)
  end

  def attributes
    @attributes ||= {}
  end
  
  def attribute_values
    attributes.values
  end

  def insert
    col_names = self.class.columns.reject {|k, v| k == :id }
    question_marks = (["?"] * col_names.length).join(", ")
    col_names = col_names.join(", ")
    
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO #{self.class.table_name} (#{col_names})
    VALUES (#{question_marks})
    SQL
    
    @attributes[:id] = DBConnection.last_insert_row_id
  end

  def initialize(params={})
    sym_params = {}
    params.each do |k, v|
      sym_params[k.to_sym] = v
    end
    
    sym_params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
    end
    
    @attributes = sym_params
  end

  def save
    @attributes[:id] ? update : insert
  end

  def update
    set_line = attributes.map {|attr_name, _| "#{attr_name} = ?"}.join(", ")
    attr_vals = attribute_values.reject {|k, v| k == :id}
    DBConnection.execute(<<-SQL, *attr_vals, @attributes[:id])
    UPDATE #{self.class.table_name}
    SET #{set_line}
    WHERE id = ?
    SQL
  end
end
