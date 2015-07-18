require 'dotenv'
Dotenv.load

require_relative 'lib/cuties_in_chemnitz'

desc "Tweet random pet."
task :twitter do
  Twit.new(AdoptAPet.random).tweet
end

task :default => :twitter
