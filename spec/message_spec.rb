require_relative "spec_helper"

describe "Message object" do

  describe "#length2" do
    it "takes a message and returns the length" do
      message = Interested.new().to_s
      print message
      result = message.msg_id
      expect(result).to eql 1
    end
  end

  describe "#length" do
    it "takes a message and returns the length" do
      message = Message.construct_from_message("\x00\x00\x00\x01\x05")

      result = message.length
      expect(result).to eql 1
    end
  end

  describe "#type" do
    it "takes a message and returns the message type" do
      message = Message.construct_from_message("\x00\x00\x00\x01\x05")

      result = message.type
      expect(result).to eql :bitfield
    end
  end

  describe "#payload" do
    it "takes a message and doesn't return the payload when there is none" do
      message = Message.construct_from_message("\x00\x00\x00\x01\x02")

      result = message.payload
      expect(result).to eql nil
    end

    it "takes a message and returns the payload when there is one" do
      message = Message.construct_from_message("\x00\x00\x00\x05\x02\x00\x00\x00\x05")

      result = message.payload
      expect(result).to eql "\x00\x00\x00\x05"
    end
  end

  describe "#parse_message" do
    it "takes message bytes and returns a keep alive message" do

      result = Message.parse_message("\x00\x00\x00\x00")
      expect(result).to be_a Message::Message
      expect(result.id).to be -1
      expect(result.type).to be :keep_alive
      expect(result.hasPayload).to be false
    end

    it "takes message bytes and returns a choke message" do

      result = Message.parse_message("\x00\x00\x00\x01\x00")
      expect(result).to be_a Message::Message
      expect(result.id).to be 0
      expect(result.type).to be :choke
      expect(result.hasPayload).to be false
    end

    it "takes message bytes and returns an unchoke message" do

      result = Message.parse_message("\x00\x00\x00\x00\x01")
      expect(result).to be_a Message::Message
      expect(result.id).to be 0
      expect(result.type).to be :choke
      expect(result.hasPayload).to be false
    end


  end

end
# u0000\u0001"
#            \u0000\u0001"
#
# message length 5
#
# ======= received handshake ========
#                      Received data on 80.94.76.6:18524
# "\xFF\xFF\xFF\xFE"
# message length 1019
# Received data on 97.90
#
# "\x13BitTorrent protocol\x80\x00\x00\x00\x00\x13\x00\x04*\x9D\x12\x91\xD3s\xE4\xA6\x90hBjQ\xA8\xFE\x85\x85\xDA\xFE>-AZ5301-6zq61cDr3MVq"
# ======= received handshake ========
#                      Received data on 189.228.48.28:36756
# "\x00\x00\x00\x05\x05\xFF\xF7\x7F~\x00\x00\x00\x05\x04\x00\x00\x00\f\x00\x00\x00\x05\x04\x00\x00\x00\x10\x00\x00\x00\x05\x04\x00\x00\x00\x18"
# message length 5
# Received data on 80.94.76