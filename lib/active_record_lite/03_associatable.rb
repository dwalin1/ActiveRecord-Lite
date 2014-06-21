require_relative '02_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      foreign_key: "#{name}_id".to_sym,
      primary_key: :id,
      class_name: name.to_s.camelcase
    }
    
    attrs = defaults.merge(options)
          
    @foreign_key = attrs[:foreign_key]
    @primary_key = attrs[:primary_key]
    @class_name = attrs[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      foreign_key: "#{self_class_name.underscore}_id".to_sym,
      primary_key: :id,
      class_name: name.to_s.camelcase.singularize
    }
    
    attrs = defaults.merge(options)
          
    @foreign_key = attrs[:foreign_key]
    @primary_key = attrs[:primary_key]
    @class_name = attrs[:class_name]
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    #name should be the name of the method I build
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    
    define_method name.to_s do
      f_key_val = self.send(options.foreign_key)
      row = DBConnection.execute(<<-SQL, f_key_val)
      SELECT * FROM #{options.table_name}
      WHERE #{options.primary_key} = ?
      SQL
      .first
      options.model_class.new(row)
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    
    define_method name.to_s do
      p_key_val = self.send(options.primary_key)
      DBConnection.execute(<<-SQL, p_key_val)
      SELECT * FROM #{options.table_name}
      WHERE #{options.foreign_key} = ?
      SQL
      .map { |row| options.model_class.new(row) }
    end
  end

  def assoc_options
    # Wait to implement this in Phase V. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
