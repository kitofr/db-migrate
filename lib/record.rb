require File.join(File.dirname(__FILE__), 'table')

module Active
  class Record
    include Active::Table

    def self.inherited(child)
      @child = child
      def self.name
        @child
      end
      column_names.each do |column|
        define_method(column.downcase) do
          column.downcase
        end
      end
    end

    def self.all
      class << self
        include Active::Table
        def self.name
          m, name = self.to_s.match(/:([\w]+)\>/), $1
          name
        end

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
