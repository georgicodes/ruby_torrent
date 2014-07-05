class Peer < EM::Connection

  def initialize(host, port, handshake)
    @host = host
    @port = port
    @handshake = handshake

    @am_choking = true
    @am_interested = false
    @peer_choking = true
    @peer_interested = false # false when remote peer is not interested in requesting blocks from this client
  end

  def post_init
    print "===> Sending Handshake to #{@host}:#{@port} <=== ".blue
    puts @handshake.inspect.blue
    send_data(@handshake)
  end

  def receive_data(data)
    parse_message(data)
  end

  #TODO: refactor message parsing into own class
  def parse_handshake_response(response)
    # pstrlen = response.getbyte(0)
    # @handshake_respone = {
    #     :pstrlen => pstrlen,
    #     :pstr => response.read(pstrlen),
    #     :reserved => response.read(8),
    #     :info_hash => response.read(20),
    #     :peer_id => response.read(20)
    # }
    print "===> Handshake response received on #{@host}:#{@port} <=== ".colorize(:yellow)
    puts response.inspect.colorize(:yellow)

    send_message(InterestedMessage.new().formatted_message)
  end

  def send_message(msg_to_send)
    print "===> Sending message to #{@host}:#{@port} <=== ".blue
    puts msg_to_send.inspect.blue
    send_data(msg_to_send)
  end

  def parse_message(message)
    if (message.include?("BitTorrent protocol"))
      parse_handshake_response(message)
    else
      print "===> Received message on #{@host}:#{@port} <=== ".colorize(:light_green)
      puts message.inspect.green
      torrent_message = MessageFactory.construct_from_bytes(message)
      ap torrent_message
      # message_length = Message.parse_message_length(message)
      # print "message length #{message_length} "
      # msg_id = Message.parse_message_id(message)
      # print "message id #{msg_id}"
      # payload = Message.parse_payload(message)
      # print "payload #{payload}"
    end
  end

end
