module DatabaseMigrate
  class Database
    attr_accessor :database_name, :database_server, :user, :password, :debug, :dry_run

    def initialize(database_server, database_name, user, password)
      @database_server, @database_name, @user, @password =  database_server, database_name, user, password
      @output = ""
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
      puts "Migrating from: #{current_revision} to #{to}" unless @dry_run 
      
      start_index = find_index(scripts, current_revision)
      to_index = find_index(scripts, to)
      scripts[start_index...to_index].each do |script|
        number = script_number(script)
        create_changelog_entry(number, script)
        raise "Failed to apply #{script}" unless apply(script)
        if debug
          puts "Applied: #{File.basename(script)}" unless @dry_run
        else
          print "." unless @dry_run
        end
        update_changelog_entry(number)
      end
      puts "", "[done]" unless @dry_run
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
      return 0 if @dry_run
      response = query "SELECT TOP(1) Change_Number FROM [ChangeLog] ORDER BY Change_Number DESC"
      row = @debug ? 3 : 2
      response.split("\n")[row].to_i
    end

    def apply(file)
      sqlcmd(file, "-d #{@database_name}", true)
    end

    def query(command)
      sqlcmd(command, "-d #{@database_name}")
    end

    def execute(command)
      sqlcmd(command)
    end

    def sqlcmd(command, catalog_name = "", file = false)
      run_option = file ? "-i" : "-Q"

      return handle_output(command, file) if @dry_run

      `SqlCmd.exe -S #{@database_server} #{run_option} \"#{command}\" -U #{@user} -P #{@password} #{catalog_name} #{debug}`
    end

    def handle_output(command, file)
      if file
        @output << "--------- [#{File.basename(command)}]\n"
        File.open(command).each_line { |l| @output << l }
      else
        @output << "---------\n#{command}" unless file
      end
      @output << "\n"
      true
    end

    def output
      @output
    end

    private
    def debug
      "-e" if @debug
    end
  end
end
