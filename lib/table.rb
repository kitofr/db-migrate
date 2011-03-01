require File.join(File.dirname(__FILE__), 'db-migrate')
module Active
  module Table
    @data_type_query = <<QUERY
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ChangeLog'
QUERY

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def database 
        Active::Database.new("sql02.qb.local", "kitofr_test", "AppUserBetaWithPassword", "password")
      end
      def query
        @x ||= database.query "SELECT * FROM [#{name}]"
      end
      def rows
        query.split("\n")
      end
      def column_names
        rows.first.rstrip.split(" ").collect {|name| name.downcase}
      end
      def column_lengths
        rows[1].split(" ").collect do |column|
          column.length 
        end
      end
      def data
        rows[2..-2].collect do |row|
          cnt = 0
          unless row.empty? || row.nil?
            (column_names.zip(column_lengths)).collect do |name, length|
              data = row[cnt..(cnt+length)]
              collector = [ name.to_sym, data.strip ]
              cnt += length + 1
              collector
            end
          end
        end.compact!.collect { |row| row.inject({}, &to_hash) }
      end
      def to_hash 
        lambda{|res,e| res[e.first] = e.last; res }
      end
      def debug(x)
        puts x 
        x
      end
    end
  end
end
