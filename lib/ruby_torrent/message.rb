class BaseMessage

  attr_reader :message_id, :payload

  def initialize(message_id, payload = nil)
    @message_id = message_id
    @payload = nil
  end

  def formatted_message
    length_prefix + @message_id.chr
  end

  def length_prefix
    length_str = "%04d" % length
    result = []

    length_str.split("").each do |value|
      result << value.to_i.chr
    end

    result.join("")
  end

  def length
    return 1 unless @payload
    return 1 + @payload.length
  end
end

class ChokeMessage < BaseMessage
  MSG_ID = 0

  def initialize
    super(MSG_ID)
  end

  def action_message(peer)
    peer.peer_choking = true
  end
end

class UnchokeMessage < BaseMessage
  MSG_ID = 1

  def initialize
    super(MSG_ID)
  end

  def action_message(peer)
    peer.peer_choking = false
  end
end

class InterestedMessage < BaseMessage
  MSG_ID = 2

  def initialize
    super(MSG_ID)
  end

  def action_message(peer)
    peer.peer_interested = true
  end
end

class NotInterestedMessage < BaseMessage
  MSG_ID = 3

  def initialize
    super(MSG_ID)
  end

  def action_message(peer)
    peer.peer_interested = false
  end
end

class HaveMessage < BaseMessage
  MSG_ID = 4

  def initialize(payload)
    super(MSG_ID, payload)
  end

  def action_message(peer)
    # update bitfield for peer with have
  end
end

class BitfieldMessage < BaseMessage
  MSG_ID = 5

  def initialize(payload)
    super(MSG_ID, payload)
  end

  def action_message(peer)
    # set bitarray  for peer
  end
end

# The request message is fixed length, and is used to request a block. The payload contains the following information:
# index: integer specifying the zero-based piece index
# begin: integer specifying the zero-based byte offset within the piece
# length: integer specifying the requested length. Use 2^14 (16KB)
class RequestMessage < BaseMessage
  MSG_ID = 6

  def initialize(payload)
    super(MSG_ID, payload)
  end
end

class PieceMessage < BaseMessage
  MSG_ID = 7

  def initialize(payload)
    super(MSG_ID, payload)
  end
end

# The cancel message is fixed length, and is used to cancel block requests. The payload is identical to that of the
# "request" message. It is typically used during "End Game".
class CancelMessage < BaseMessage
  MSG_ID = 8

  def initialize(payload)
    super(MSG_ID, payload)
  end
end

# The port message is sent by newer versions of the Mainline that implements a DHT tracker. The listen port is the
# port this peer's DHT node is listening on. This peer should be inserted in the local routing table (if DHT tracker is supported).
class PortMessage < BaseMessage
  MSG_ID = 9

  def initialize(payload)
    super(MSG_ID, payload)
  end
end

class MessageFactory
  def self.construct_from_bytes(message)

    message_id = self.parse_message_id(message)

    case message_id
    when 0
      return ChokeMessage.new
    when 1
      return UnchokeMessage.new
    when 2
      return InterestedMessage.new
    when 3
      return NotInterestedMessage.new
    when 4
      payload = self.parse_payload(message)
      return HaveMessage.new(payload)
    when 5
      payload = self.parse_payload(message)
      return BitfieldMessage.new(payload)
    when 6
      payload = self.parse_payload(message)
      return RequestMessage.new(payload)
    when 7
      payload = self.parse_payload(message)
      return PieceMessage.new(payload)
    when 8
      payload = self.parse_payload(message)
      return CancelMessage.new(payload)
    when 9
      payload = self.parse_payload(message)
      PortMessage.new(payload)
    end
  end

  def self.parse_message_id(message)
    id = message[4]
    return -1 unless id
    id.ord
  end

  def self.parse_message_length(message)
    str = ""
    message[0...4].each_byte do |byte|
      str += byte.ord.to_s
    end
    str.to_i
  end

  # TODO refactor -> this is messy and not working quite right
  def self.parse_payload(message)
    length = MessageFactory.parse_message_length(message)
    return nil unless length > 1

    message_byte_array = message.bytes
    message_byte_array = message_byte_array.drop(5) # drop first 4 byte msg length + msg id

    return message_byte_array
  end
end