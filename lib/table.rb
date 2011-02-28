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
      def query
	<<EOS
Change_Number Delta_Set  Start_Dt                Complete_Dt             Applied_By                                                                                           Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
------------- ---------- ----------------------- ----------------------- ---------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            1 Main       2011-02-23 22:06:44.900 2011-02-23 22:06:45.310 dto                                                                                                  1 Create country Australia.sql                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
            2 Main       2011-02-23 22:06:45.470 2011-02-23 22:06:45.803 dto                                                                                                  2 Alter sp for Australia.sql                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
            3 Main       2011-02-23 22:06:45.913 2011-02-23 22:06:46.293 dto                                                                                                  3 Alter table TransactionBatch.sql                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  

(3 rows affected)
EOS
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
    end
  end
end
