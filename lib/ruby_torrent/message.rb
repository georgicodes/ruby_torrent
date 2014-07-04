# Construct a message from bytes
# Construct a message from type
# message should have id, payload
class BaseMessage
  LENGTH_PREFIX_NO_PAYLOAD = "\x00\x00\x00\x01"

  attr_reader :message_id, :payload

  def initialize(message_id, payload = nil)
    @message_id = message_id
    @payload = nil
  end

  def to_s
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

class Choke < BaseMessage
  MSG_ID = 1

  def initialize
    super(MSG_ID)
  end
end

class Interested < BaseMessage
  MSG_ID = 2

  def initialize
    super(MSG_ID)
  end
end

class NotInterested < BaseMessage
  MSG_ID = 3

  def initialize
    super(MSG_ID)
  end
end

class Have < BaseMessage
  MSG_ID = 4

  def initialize(payload)
    super(MSG_ID, payload)
  end
end

class MessageFactory
  def self.new_from_bytes(message)

    message_id = self.parse_message_id(message)
    # type = MESSAGE_TYPES[msg_id.to_s]
    # length = self.parse_message_length(message)
    # payload = self.parse_payload(message)

    case message_id
      when message_id == 1
        return Choke.new
      when message_id == 2
        return Interested.new
      when message_id == 3
        return NotInterested.new
    end
  end

  def self.parse_message_id(message)
    id = message[4]
    return -1 unless id
    id.ord
  end

  # #TODO should only be used for validation purposes
  # def self.parse_message_length(message)
  #   str = ""
  #   message[0...4].each_byte do |byte|
  #     str += byte.ord.to_s
  #   end
  #   str.to_i
  # end
  #
  # #TODO: refactor this is messy
  # def self.parse_payload(message)
  #   length = Message.parse_message_length(message)
  #   return nil unless length > 1
  #
  #   message_byte_array = message.bytes
  #   message_byte_array = message_byte_array.drop(5) # drop first 4 byte msg length + msg id
  #
  #   return message_byte_array
  # end
end

temp = Interested.new()
p temp.to_s
p temp.message_id
p temp.length_prefix
puts

mf = MessageFactory.new_from_bytes("")
p mf.to_s
p mf.message_id
p mf.length_prefix
#
#
# class Message
#
#   #TODO refactor message class: possibly have indiv classes eg Interested < Message
#   MESSAGE_TYPES = {
#       "-1" => :keep_alive,
#       "0" => :choke,
#       "1" => :unchoke,
#       "2" => :interested,
#       "3" => :not_interested,
#       "4" => :have,
#       "5" => :bitfield,
#       "6" => :request,
#       "7" => :piece,
#       "8" => :cancel
#   }
#
#   attr_reader :type, :length, :payload
#
#   def self.construct_from_message(message)
#     msg_id = self.parse_message_id(message)
#     type = MESSAGE_TYPES[msg_id.to_s]
#
#     length = self.parse_message_length(message)
#
#     payload = self.parse_payload(message)
#     self.new(msg_id, type, length, payload)
#   end
#
#   def self.construct_from_type(type, payload=nil)
#     msg_id = MESSAGE_TYPES.key(type)
#     self.new(msg_id, type, 1) #TODO shouldn't have to set length in constructor
#   end
#
#   def initialize(msg_id, type, length, payload = nil)
#     @msg_id = msg_id
#     @type = type
#     @length = length
#     @payload = payload
#   end
#
#   def to_s
#     "Message type => #{@type} of length #{@length} with payload #{@payload}"
#   end
#
#   def formatted_message
#     return "\x00\x00\x00\x01\x02"
#     # length_as_formatted_bytes + @msg_id.chr
#   end
#
#   # pads left 0's for length of 4
#   def length_as_formatted_bytes
#     length_str = "%04d" % @length
#     result = ""
#
#     length_str.each_char do |value|
#       result += value.chr
#     end
#     return length_str
#   end
#
#   def self.parse_message_id(message)
#     id = message[4]
#     return -1 unless id
#     id.ord
#   end
#
#   #TODO should only be used for validation purposes
#   def self.parse_message_length(message)
#     str = ""
#     message[0...4].each_byte do |byte|
#       str += byte.ord.to_s
#     end
#     str.to_i
#   end
#
#   #TODO: refactor this is messy
#   def self.parse_payload(message)
#     length = Message.parse_message_length(message)
#     return nil unless length > 1
#
#     message_byte_array = message.bytes
#     message_byte_array = message_byte_array.drop(5) # drop first 4 byte msg length + msg id
#
#     return message_byte_array
#   end
#
# end

