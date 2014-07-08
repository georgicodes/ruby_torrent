module MsgUtil

  # converts int to 4 byte (32bit) big-endian byte string
  def self.pack_int_to_four_bytes_str(value)
    [value].pack("N")
  end

  # converts single int to 1 byte (8bit) string
  def self.pack_int_to_single_byte_str(value)
    value.chr
  end

  def self.unpack_int_from_bytes(bytes)
    bytes.unpack("N")[0]
  end

end

class BaseMessage

  attr_reader :message_id, :payload

  def initialize(message_id, payload = nil)
    @message_id = message_id
    @payload = payload
  end

  def formatted_message
    formatted_length + formatted_id
  end

  def formatted_length
    MsgUtil.pack_int_to_four_bytes_str(length)
  end

  def formatted_id
    MsgUtil.pack_int_to_single_byte_str(@message_id)
  end

  def length
    return 1 unless @payload
    return 1 + @payload.length
  end

  def inspect
    print (self.class.name + " with ID: " + @message_id.to_s).colorize(:light_yellow)
    if (@payload)
      print " and Payload: ".colorize(:light_yellow)
      print @payload.inspect.colorize(:light_yellow)
    end
  end
end

class KeepAliveMessage < BaseMessage
  MSG_ID = -2

  def initialize
    super(MSG_ID)
  end
end

class HandshakeMessage < BaseMessage
  MSG_ID = -1

  def initialize(payload)
    super(MSG_ID, payload)
  end
end

class ChokeMessage < BaseMessage
  MSG_ID = 0

  def initialize
    super(MSG_ID)
  end
end

class UnchokeMessage < BaseMessage
  MSG_ID = 1

  def initialize
    super(MSG_ID)
  end
end

class InterestedMessage < BaseMessage
  MSG_ID = 2

  def initialize
    super(MSG_ID)
  end
end

class NotInterestedMessage < BaseMessage
  MSG_ID = 3

  def initialize
    super(MSG_ID)
  end
end

class HaveMessage < BaseMessage
  MSG_ID = 4

  def initialize(payload)
    super(MSG_ID, payload)
  end
end

class BitfieldMessage < BaseMessage
  MSG_ID = 5

  def initialize(payload)
    super(MSG_ID, payload)
  end
end

# The request message is fixed length, and is used to request a block. The payload contains the following information:
# index: integer specifying the zero-based piece index
# begin: integer specifying the zero-based byte offset within the piece
# length: integer specifying the requested length. Use 2^14 (16KB)
class RequestMessage < BaseMessage
  MSG_ID = 6

  attr_reader :piece_index, :byte_offset, :block_length

  # TODO refactor like PieceMessage
  def initialize(args)
    payload = args[:payload] || nil
    super(MSG_ID, payload)

    if !payload
      @piece_index = args[:piece_index]
      @byte_offset = args[:byte_offset]
      @block_length = args[:block_length]
      @payload ||= formatted_request_message
    else
      # TODO extract values from payload
      @piece_index = nil
      @byte_offset = nil
      @block_length = nil
    end
  end

  def formatted_message
    super + formatted_request_message
  end

  def formatted_request_message
    formatted_piece_index + formatted_byte_offset + formatted_block_length
  end

  private
  def formatted_piece_index
    MsgUtil.pack_int_to_four_bytes_str(@piece_index)
  end

  def formatted_byte_offset
    MsgUtil.pack_int_to_four_bytes_str(@byte_offset)
  end

  def formatted_block_length
    MsgUtil.pack_int_to_four_bytes_str(@block_length)
  end
end

# The piece message is variable length, where X is the length of the block. The payload contains the following information:
# index: integer specifying the zero-based piece index
# begin: integer specifying the zero-based byte offset within the piece
# block: block of data, which is a subset of the piece specified by index.
class PieceMessage < BaseMessage
  MSG_ID = 7

  def initialize(args)
    payload = args[:payload]
    @piece_index = args[:piece_index]
    @byte_offset = args[:byte_offset]
    @block_data = args[:block_data]
    super(MSG_ID, payload)
  end

  def self.build_from_payload(message)
    args = {}
    args[:payload] = message[5..-1]

    stream = StringIO.new(message)
    length = MsgUtil.unpack_int_from_bytes(stream.read(4))
    stream.read(1) # msg_id

    args[:piece_index] = stream.read(4)
    args[:byte_offset] = stream.read(4)
    args[:block_data] = stream.read(length - 9)
    return self.new(args)
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

    length = self.parse_message_length(message)
    return KeepAliveMessage.new unless length > 0

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
        return PieceMessage.build_from_payload(message)
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