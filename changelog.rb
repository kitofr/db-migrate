
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
  def self.rows
    query.split("\n")
  end
  def self.column_names
    rows.first.rstrip.split(" ").collect {|name| name.downcase}
  end
  def self.column_lengths
    rows[1].split(" ").collect do |column|
      column.length 
    end
  end
  def self.data
    rows[2..-2].collect do |row|
      cnt, i = 0, 0
      unless row.empty? || row.nil?
	column_lengths.collect do |length|
	  data = row[cnt..(cnt+length)]
	  collector = [ column_names[i].to_sym, data.strip ]
	  cnt += length + 1
	  i += 1
	  collector
	end
      end
    end.compact!.collect do |row|
      row.inject({}) do |result, element|
	result[element.first] = element.last
	result
      end
    end
  end
end

class Record
  Db.column_names.each do |column|
    define_method(column.downcase) do
      column.downcase
    end
  end

  def self.all
    class << self
      m = self.to_s.match(/:([\w]+)\>/)
      name = $1
      Db.data.collect do |row|
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

class Changelog < Record
end

puts "Class: #{Changelog.name}"
puts "Methods: #{(Changelog.new.methods.sort - Object.methods).join(",")}"
Changelog.all.each do |changelog|
  puts changelog.inspect
end
