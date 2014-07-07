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

    @message_bytes = ""
  end

  def post_init
    print "===> Sending Handshake to #{@host}:#{@port} <=== ".blue
    puts @handshake.inspect.blue
    send_data(@handshake)
  end

  def receive_data(data_received)
    parse_message(data_received)
  end

  #TODO: refactor message parsing into own class
  def parse_handshake_response_and_send_interested_message(response)
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
    print "===> Handshake response received on #{@host}:#{@port} <=== ".colorize(:yellow)
    puts response.inspect.colorize(:yellow)

    send_message(InterestedMessage.new.formatted_message)
  end

  def send_message(msg_to_send)
    print "===> Sending message to #{@host}:#{@port} <=== ".blue
    puts msg_to_send.inspect.blue
    send_data(msg_to_send)
  end

  def parse_message(data_received)
    # TODO can this check be a bit cleaner?
    if (data_received.include?("BitTorrent protocol"))
      handshake_response = data_received.read(68) # TODO refactor magic number
      parse_handshake_response_and_send_interested_message(handshake_response)
    end

    print "===> Received message on #{@host}:#{@port} <=== ".colorize(:light_green)
    puts message.inspect.green
    torrent_message = MessageFactory.construct_from_bytes(message)
    handle_message(torrent_message)
  end

  def handle_message(torrent_message)
    return unless torrent_message
    ap torrent_message
    torrent_message.action_message(self)
  end

  def peer_choking=(isChoking)
    @peer_choking = isChoking

    if (!@peer_choking)
      puts "Peer no longer choking, may request blocks"

      msg = request_next_block
      send_message(msg)
    end
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
