require 'data'
require 'json'
require 'pp'

describe DataGrabber do
    it "loads the player1 data" do
        data = get("player1")
        data.keys.length.should == 6
        data.should include("youmu")
    end
end
