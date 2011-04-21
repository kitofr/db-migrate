require 'lib/table'
require 'lib/record'

class Changelog < Active::Record
end

class Project < Active::Record
end

puts "Class: #{Changelog.name}"
puts "Methods: #{(Changelog.new.methods.sort - Object.methods).join(",")}"
Changelog.all.each do |changelog|
  puts changelog.inspect
end

project =  Project.new
puts project.methods - Object.methods
#.each do |project|
#  puts project.inspect
#end
