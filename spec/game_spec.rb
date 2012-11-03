require 'game'
require 'json'
require 'pp'

class SocketMock
    @@nextSocketID = 0
    def initialize
        @messages = []
        @id = @@nextSocketID
        @@nextSocketID += 1
    end

    def send(message)
        @messages << message
    end

    def messages
        @messages.collect {|m| JSON.parse(m)}
    end

    def messages_with_type(type)
        messages.find_all {|m| m["type"] == type}
    end

    def id
        @id
    end
end

def send_messages(players, messages)
    sockets = []
    players.times do
        socket = SocketMock.new
        sockets << socket
        @int.addPlayer(socket)
    end
    messages.length.times do |i|
        @int.message(sockets[i], messages[i])
    end
    return sockets
end

def dummy_callback(args)
    pp args
end

def dummy_legality(args)
    true
end

class HaveStartingMessages
    def matches?(target)
        target.messages.length.should == 1
        message = target.messages[0]
        message["type"].should == "data"
        message.should include("my_stacks")
        message.should include("heroes")
        message.should include("spellcards")
        message.should include("items")
    end
end
def have_starting_messages
    HaveStartingMessages.new
end

class HaveStartedGameWith
    def initialize(opponent)
        @opponent = opponent
    end
    def matches?(target)
        target.messages.length.should == 2
        message = target.messages[1]
        message["type"].should == "data"
        message["phase"].should == "begin_game"
        message.should include("enemy_stacks")
    end
end
def have_started_game_with
    HaveStartedGameWith.new
end

describe Game::Interface do
    before :each do
        @int = Game::Interface.new
    end

    it "Sends one chat message to one player" do
        sockets = send_messages(1, [{"type" => "chat", "message" => "hello"}])
        sockets[0].messages_with_type("chat").should eq([{"type" => "chat", "message" => "hello"}])
    end

    it "Sends one chat message to two players" do
        sockets = send_messages(2, [{"type" => "chat", "message" => "hello"}])
        sockets[0].messages_with_type("chat").should eq([{"type" => "chat", "message" => "hello"}])
        sockets[1].messages_with_type("chat").should eq([{"type" => "chat", "message" => "hello"}])
    end

    it "Sends two chat messages to two players" do
        sockets = send_messages(2, [{"type" => "chat", "message" => "hello"},
                                    {"type" => "chat", "message" => "world"}])
        sockets[0].messages_with_type("chat").should eq([{"type" => "chat", "message" => "hello"},
                                                    {"type" => "chat", "message" => "world"}])
        sockets[1].messages_with_type("chat").should eq([{"type" => "chat", "message" => "hello"},
                                                    {"type" => "chat", "message" => "world"}])
    end

    it "Sends three chat messages split amongst three players" do
        sockets = send_messages(3, [{"type" => "chat", "message" => "hello"},
                                    {"type" => "chat", "message" => "world"},
                                    {"type" => "chat", "message" => "!!!"}])
        sockets[0].messages_with_type("chat").should eq([{"type" => "chat", "message" => "hello"},
                                                    {"type" => "chat", "message" => "world"}])
        sockets[1].messages_with_type("chat").should eq([{"type" => "chat", "message" => "hello"},
                                                    {"type" => "chat", "message" => "world"}])
        sockets[2].messages_with_type("chat").should eq([{"type" => "chat", "message" => "!!!"}])
    end

    it "Sends the begin game message" do
        sockets = send_messages(2, [])
        sockets[0].messages.should eq([{"type" => "data", "phase" => "select_starting_hero"}])
        sockets[1].messages.should eq([{"type" => "data", "phase" => "select_starting_hero"}])
    end

    it "Doesn't send the begin game message until ready" do
        sockets = send_messages(1, [])
        sockets[0].messages.should eq([])
    end

    it "Doesn't send the begin game message to player 3" do
        sockets = send_messages(3, [])
        sockets[0].messages.should eq([{"type" => "data", "phase" => "select_starting_hero"}])
        sockets[1].messages.should eq([{"type" => "data", "phase" => "select_starting_hero"}])
        sockets[2].messages.should eq([])
    end

    it "Calls a one-player callback" do
        @int.send_mesages(1, [{}])

    end

    it "Calls a two-player callback" do
    end

    it "Rejects illegal actions" do
    end

    it "Rejects the wrong player ID" do
    end

    it "Completes a standard 2-player game start" do
        # Create the players
        p1_socket = SocketMock.new
        p1_id = "player1"
        p2_socket = SocketMock.new
        p2_id = "player2"

        @int.addPlayer(p1_socket, p1_id)
        p1_socket.should have_starting_messages
                
        @int.addPlayer(p2_socket, p2_id)
        p1_socket.should have_starting_messages

        p1_socket.should have_started_game_with(p2_socket)
        p2_socket.should have_started_game_with(p1_socket)
    end
end
