# main.rb
require 'rubygems'
require 'haml'
require 'sinatra'
require 'sinatra-websocket'
require 'json'

require 'lib/game'

# set :sockets, []
set :environment, :development

#class Gensou < Sinatra::Base
get '/' do
    haml :play
end

get '/get_data' do
end

$game_interface = Game::Interface.new

get '/socket' do
    request.websocket do |socket|
        socket.onopen do
            $game_interface.addPlayer(socket)
            socket.send(JSON.dump({"type" => "ready"}))
        end
        socket.onmessage do |message|
            print "Got message: #{message}\n"
            m = JSON.parse(message)
            $game_interface.message(socket, m)
        end
    end
end

