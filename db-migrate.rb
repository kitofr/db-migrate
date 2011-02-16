module DatabaseMigrate
  class Database
    attr_accessor :database_name, :database_server, :user, :password, :debug

    def initialize(database_server, database_name, user, password)
      @database_server, @database_name, @user, @password =  database_server, database_name, user, password
    end

    def drop
      drop_command = <<EOS 
USE master; 
IF EXISTS(SELECT name FROM master..sysdatabases WHERE name = N'#{@database_name}') 
  BEGIN ALTER DATABASE [#{@database_name}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; 
  DROP DATABASE #{@database_name} 
END
EOS
      execute(drop_command)
    end

    def create
      create_command = <<EOS
CREATE DATABASE	[#{@database_name}]
EOS
      execute(create_command)	
    end

    def migrate(migration_dir, to=nil)
      scripts = migrations(migration_dir)
      to = script_number(scripts.last) unless to
      if current_revision == to
        puts "Allready at current revision. Nothing to migrate to."
	return
      end
      puts "Migrating from: #{current_revision} to #{to}" 
      
      start_index = find_index(scripts, current_revision)
      to_index = find_index(scripts, to)
      scripts[start_index...to_index].each do |script|
	number = script_number(script)
	create_changelog_entry(number, script)
	raise "Failed to apply #{script}" unless apply(script)
	if debug
	  puts "Applied: #{File.basename(script)}"
	else
	  print "."
	end
	update_changelog_entry(number)
      end
      puts "", "[done]"
    end
    
    def find_index(scripts, number)
      return 0 if number == 0
      scripts.index(scripts.find { |x| x =~ /#{number}\s/ }) + 1
    end

    def create_changelog_entry(number, script)
	update_changelog = <<EOS
INSERT INTO ChangeLog (Change_Number, Delta_Set, Start_Dt, Applied_By, Description) 
VALUES (#{number}, 'Main', GETDATE(), 'dto', '#{File.basename(script)}')
EOS
	raise "Could not update changelog" unless query(update_changelog)
    end

    def update_changelog_entry(number)
      raise "Failed to complete changelog update" unless query("UPDATE ChangeLog SET Complete_Dt = GETDATE() WHERE Change_Number = #{number}")
    end

    def script_number(script)
      begin
        File.basename(script)[/[\d]+/].to_i
      rescue
	puts "Failed to find number on: <#{script}>"
      end
    end

    def migrations(migration_dir)
       entries = Dir.glob(File.join(migration_dir, '*.sql'))
       entries.sort_by do |entry|
	 script_number(entry)
       end
    end
    
    def current_revision
      response = query "SELECT TOP(1) Change_Number FROM [ChangeLog] ORDER BY Change_Number DESC"
      response.split("\n")[2].to_i
    end

    def apply(file)
      `SqlCmd.exe -S #{@database_server} -d #{@database_name} -i \"#{file}\" -U #{@user} -P #{@password} #{debug}` if File.exists?(file) 
    end

    def query(command)
      `SqlCmd.exe -S #{@database_server} -d #{@database_name} -Q \"#{command}\" -U #{@user} -P #{@password} #{debug}`
    end

    def execute(command)
      `SqlCmd.exe -S #{@database_server} -Q \"#{command}\" -U #{@user} -P #{@password} #{debug}`
    end
    private
    def debug
      "-e" if @debug
    end
  end
end
