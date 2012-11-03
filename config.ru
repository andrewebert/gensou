require 'rubygems'
require 'sinatra'
require '/home/ai_zakharov/www/web.rb'
#require 'web.rb'

root_dir = File.dirname(__FILE__)

#require root_dir + '/gensou.rb'

set :environment, :production
set :app_file, '/home/ai_zakharov/www/web.rb'
#set :root,  root_dir
#set :app_file, File.join(root_dir, 'web.rb')
disable :run

FileUtils.mkdir_p 'log' unless File.exists?('log')
log = File.new("log/sinatra.log", "a")
$stdout.reopen(log)
$stderr.reopen(log)

run Sinatra::Application
