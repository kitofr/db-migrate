class Db
  def self.query
    <<EOS
Change_Number Delta_Set  Start_Dt                Complete_Dt             Applied_By                                                                                           Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
------------- ---------- ----------------------- ----------------------- ---------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            1 Main       2011-02-23 22:06:44.900 2011-02-23 22:06:45.310 dto                                                                                                  1 Create country Australia.sql                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
            2 Main       2011-02-23 22:06:45.470 2011-02-23 22:06:45.803 dto                                                                                                  2 Alter sp for Australia.sql                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
            3 Main       2011-02-23 22:06:45.913 2011-02-23 22:06:46.293 dto                                                                                                  3 Alter table TransactionBatch.sql                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  

(3 rows affected)
EOS
  end
end

class Record
  def self.on_each_column_in(columns)
    columns.split(" ").each do |column| 
      yield(column)
    end
  end

  columns = Db.query.split("\n").first.rstrip
  on_each_column_in(columns) do |column|
    define_method(column.downcase) do
      column.downcase
    end
  end

  def self.all
    class << self
      m = self.to_s.match(/:([\w]+)\>/)
      name = $1
      puts "name => #{name}"

      data = Db.query.split("\n")

      data[1].each do |row|
        Record.on_each_column_in(row) do |column|
	  puts "column.length: <#{column.length}>"
	end
      end

      return data[2..4].collect do |row|
        record = (eval name).new	
	record
      end      
    end
  end
end

class Changelog < Record
end

puts "Class: #{Changelog.name}"
puts "Methods: #{(Changelog.new.methods.sort - Object.methods).join(",")}"
puts Changelog.all
