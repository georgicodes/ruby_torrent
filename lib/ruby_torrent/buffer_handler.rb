class BufferHandler

  attr_reader :incoming_messages

  def initialize
    @buffer = StringIO.new
    @incoming_messages = []
  end

  def <<(data)
    @buffer.write(data)

    parse_incoming_buffer_into_messages
  end

  def parse_incoming_buffer_into_messages
    if msg_is_handshake?
      parse_handshake
    else

    end
  end

  def parse_handshake
    handshake_response = @buffer.read(Handshake::HANDSHAKE_SIZE)
    handshake_message = HandshakeMessage.new(handshake_response)
    @incoming_messages << handshake_message
  end

  def msg_is_handshake?()
    @buffer.size == Handshake::HANDSHAKE_SIZE && @buffer.string.include?("BitTorrent protocol")
  end

end