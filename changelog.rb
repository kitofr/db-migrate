class Db
  def self.query
    <<EOS
Change_Number Delta_Set  Start_Dt                Complete_Dt             Applied_By                                                                                           Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
------------- ---------- ----------------------- ----------------------- ---------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

(0 rows affected)
EOS
  end
end

class Record
  columns = Db.query.split("\n").first.rstrip
  columns.split(" ").each do |column| 
    define_method(column.downcase) do
      column.downcase
    end
  end
end

class Changelog < Record
end

puts "Class: #{Changelog.name}"
puts "Methods: #{(Changelog.new.methods.sort - Object.methods).join(",")}"
