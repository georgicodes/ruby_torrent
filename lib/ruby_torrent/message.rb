class Message

  #TODO refactor message class: possibly have indiv classes eg Interested < Message
  MESSAGE_TYPES = {
      "-1" => :keep_alive,
      "0" => :choke,
      "1" => :unchoke,
      "2" => :interested,
      "3" => :not_interested,
      "4" => :have,
      "5" => :bitfield,
      "6" => :request,
      "7" => :piece,
      "8" => :cancel
  }

  attr_reader :type, :length, :payload

  def self.construct_from_message(message)
    msg_id = self.parse_message_id(message)
    type = MESSAGE_TYPES[msg_id.to_s]

    length = self.parse_message_length(message)

    payload = self.parse_payload(message)
    self.new(msg_id, type, length, payload)
  end

  def self.construct_from_type(type, payload=nil)
    msg_id = MESSAGE_TYPES.key(type)
    self.new(msg_id, type, 1) #TODO shouldn't have to set length in constructor
  end

  def initialize(msg_id, type, length, payload = nil)
    @msg_id = msg_id
    @type = type
    @length = length
    @payload = payload
  end

  def to_s
    "Message type => #{@type} of length #{@length} with payload #{@payload}"
  end

  def formatted_message
    return "\x00\x00\x00\x01\x02"
    # length_as_formatted_bytes + @msg_id.chr
  end

  # pads left 0's for length of 4
  def length_as_formatted_bytes
    length_str = "%04d" % @length
    result = ""

    length_str.each_char do |value|
      result += value.chr
    end
    return length_str
  end

  def self.parse_message_id(message)
    id = message[4]
    return -1 unless id
    id.ord
  end

  #TODO should only be used for validation purposes
  def self.parse_message_length(message)
    str = ""
    message[0...4].each_byte do |byte|
      str += byte.ord.to_s
    end
    str.to_i
  end

  #TODO: refactor this is messy
  def self.parse_payload(message)
    length = Message.parse_message_length(message)
    return nil unless length > 1

    message_byte_array = message.bytes
    message_byte_array = message_byte_array.drop(5) # drop first 4 byte msg length + msg id

    return message_byte_array
  end

end