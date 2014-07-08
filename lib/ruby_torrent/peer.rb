class Peer < EM::Connection

  attr_writer :peer_interested

  def initialize(host, port, handshake)
    @host = host
    @port = port
    @handshake = handshake

    @am_choking = true
    @am_interested = false
    @peer_choking = true
    @peer_interested = false # false when remote peer is not interested in requesting blocks from this client

    @buff_handler = BufferHandler.new
  end

  # TODO should this handshake logic be moved until connection is 100% established?
  def post_init
    send_handshake
  end

  def send_handshake
    print "===> Sending handshake to #{@host}:#{@port} <=== ".blue
    puts @handshake.inspect.blue
    send_data(@handshake)
  end

  # Updates BufferHandler with data from incoming stream and processes complete messages
  def receive_data(data_received)
    @buff_handler << data_received
    print "===> Received message from #{@host}:#{@port} <=== ".colorize(:light_green)
    puts data_received.inspect.colorize(:light_green)

    @buff_handler.parsed_messages.each do |message|
      handle_message(message)
    end
  end

  def send_message(msg_to_send)
    print "===> Sending message to #{@host}:#{@port} <=== ".blue
    puts msg_to_send.inspect.blue
    send_data(msg_to_send)
  end

  def handle_message(torrent_message)
    return unless torrent_message
    puts torrent_message.inspect

    case torrent_message
    when HandshakeMessage
      handle_handshake_message(torrent_message)
    when ChokeMessage
      @peer_choking = true
    when UnchokeMessage
      @peer_choking = false
      puts "Peer no longer choking, may request blocks"
      msg = request_next_block
      send_message(msg)
    when InterestedMessage
      @peer_interested = true
    when NotInterestedMessage
      @peer_interested = false
    when HaveMessage
      # if chocked, update bitfield for peer with have's
      # if unchoked, then this is data so store it
      puts "Handle have message"
    when BitfieldMessage
      # set bitarray  for peer
      puts "Handle bitfield message"
    when RequestMessage
      # send to peer
      puts "Request received for files"
    when PieceMessage
      # handle storing message data from peer
      puts "Piece received!"
    when CancelMessage
      puts "Cancel"
    when PortMessage
      puts "Port"
    end
  end

  def handle_handshake_message(torrent_message)
    parse_handshake_response(torrent_message.payload)
    # TODO validate handshake
    send_message(InterestedMessage.new.formatted_message)
  end

  def parse_handshake_response(response)
    stream = StringIO.new(response)
    pstrlen = stream.getbyte
    @handshake_respone = {
        :pstrlen => pstrlen,
        :pstr => stream.read(pstrlen),
        :reserved => stream.read(8),
        :info_hash => stream.read(20),
        :peer_id => stream.read(20)
    }
    ap @handshake_respone
  end

  BLOCK_SIZE = 14**2

  def request_next_block
    args = {}
    args[:piece_index] = 0
    args[:byte_offset] = 0
    args[:block_length] = BLOCK_SIZE

    request_message = RequestMessage.new(args)
    msg_to_send = request_message.formatted_message
    msg_to_send
  end

end
