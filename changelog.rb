require 'lib/table'
require 'lib/record'

class Changelog < Active::Record
end

puts "Class: #{Changelog.name}"
puts "Methods: #{(Changelog.new.methods.sort - Object.methods).join(",")}"
Changelog.all.each do |changelog|
  puts changelog.inspect
end
