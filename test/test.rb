require 'rubygems'

dir = File.expand_path(File.dirname(__FILE__))
Dir.glob("#{dir}/*.rb").each do |file|
  require file unless file =~ /\/test\.rb$/
end

