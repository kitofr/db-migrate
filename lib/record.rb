require File.join(File.dirname(__FILE__), 'table')

module Active
  class Record
    include Active::Table

    column_names.each do |column|
      define_method(column.downcase) do
	column.downcase
      end
    end

    def self.all
      class << self
	include Active::Table
	m = self.to_s.match(/:([\w]+)\>/)
	name = $1
	data.collect do |row|
	  klass = (eval name)
	  record = klass.new

	  row.each_pair do |prop, value|
	    klass.class_eval do
	      attr_accessor prop.to_sym
	    end
	    record.send "#{prop}=", value 
	  end
	  record
	end
      end
    end
  end
end
