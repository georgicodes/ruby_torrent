module Message

  # class Msg
  #   def self.construct_from_message(message)
  #     msg_id, type = Message.parse_message(message)
  #   end
  #
  #
  # end

  TorrentMessage = Struct.new(:id, :type, :hasPayload)

  MESSAGE_TYPES = {
      "-1" => TorrentMessage.new(-1, :keep_alive, false),
      "0" => TorrentMessage.new(0, :choke, false),
      "1" => TorrentMessage.new(1, :unchoke, false),
      "2" => TorrentMessage.new(1, :interested, false),
      "3" => TorrentMessage.new(1, :not_interested, false),
      "4" => TorrentMessage.new(1, :have, true),
      "5" => TorrentMessage.new(1, :bitfield, true),
      "6" => TorrentMessage.new(1, :request, true),
      "7" => TorrentMessage.new(1, :piece, true),
      "8" => TorrentMessage.new(1, :cancel, true),
      "9" => TorrentMessage.new(1, :port, true)
  }

  def Message.parse_message(message)
    message_length = Message.parse_message_length(message_byte_array)
    message_id = parse_message_id(message)
    message = MESSAGE_TYPES[message_id.to_s]
    return message
  end

  def Message.parse_message_length(message)
    str = ""
    message[0...4].each_byte do |byte|
      str += byte.ord.to_s
    end
    str.to_i
  end

  def Message.parse_message_id(message)
    id = message[4]
    return -1 unless id
    id.ord
  end

  #TODO: refactor this is messy
  def Message.parse_payload(message)
    length = Message.parse_message_length(message)
    return nil unless length > 1

    message_byte_array = message.bytes
    message_byte_array = message_byte_array.drop(5) # drop first 4 byte msg length + msg id

    p message_byte_array
    return message_byte_array.join("")
  end

end
