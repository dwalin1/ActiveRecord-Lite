class AttrAccessorObject
  def self.my_attr_accessor(*names)
    ivar_names = names.map {|name| "@#{name}"}
    
    names.each_index do |i|
      define_method names[i] { instance_variable_get ivar_names[i] }
      define_method "#{names[i]}=" do |set_to| 
        instance_variable_set ivar_names[i], set_to
      end
    end
  end
end
