class BufferHandler

  attr_reader :incoming_messages

  def initialize
    @buffer = ""
  end

  def <<(data)
    @buffer << data
  end

  def parsed_messages
    torrent_messages = []
    while message = parse_message
      torrent_messages << message
    end

    torrent_messages
  end

  def parse_message
    if msg_is_handshake?
      return parse_handshake
    end

    if have_complete_message?
      return parse_torrent_message
    end

    return false
  end

  def parse_torrent_message
    message_body = @buffer.slice!(0, current_message_length_with_prefix)
    MessageFactory.construct_from_bytes(message_body)
  end

  def have_complete_message?
    @buffer.length >= 4 && @buffer.length >= current_message_length_with_prefix
  end

  # message length including the length prefix
  def current_message_length_with_prefix
    current_message_length + 4
  end

  def current_message_length
    @buffer.unpack('N').first
  end

  def parse_handshake
    puts "Parsing handshake response"
    handshake_response = @buffer.slice!(0, Handshake::HANDSHAKE_SIZE)
    puts "parse handshake and now have buffer length #{@buffer.length}"
    HandshakeMessage.new(handshake_response)
  end

  def msg_is_handshake?()
    @buffer.size == Handshake::HANDSHAKE_SIZE && @buffer.include?(Handshake::HANDSHAKE_PSTR)
  end

end