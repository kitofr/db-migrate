require 'rspec'
require 'table'

describe Active::Table do
  include Active::Table

  %w{database}.each do |method|
    
    it "should add in method: #{method}" do
      puts ">> #{included_modules}"
      puts method
    end
  end

end
