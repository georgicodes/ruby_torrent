class Peer < EM::Connection

  def initialize(host, port, handshake)
    @host = host
    @port = port
    @handshake = handshake
    @first_msg = true

    @am_choking = true
    @am_interested = false
    @peer_choking = true
    @peer_interested = false # false when remote peer is not interested in requesting blocks from this client
  end

  def post_init
    send_data(@handshake)
  end

  def receive_data(data)
    puts "Received data on #{@host}:#{@port}"
    parse_message(data)
  end

  #TODO: refactor message parsing into own class
  def parse_handshake_response(response)
    @first_msg = false
    # pstrlen = response.getbyte(0)
    # @handshake_respone = {
    #     :pstrlen => pstrlen,
    #     :pstr => response.read(pstrlen),
    #     :reserved => response.read(8),
    #     :info_hash => response.read(20),
    #     :peer_id => response.read(20)
    # }
    puts "======= received handshake ========"
    # ap @handshake_respone
  end

  def parse_message(message)
    p message
    if (@first_msg)
      parse_handshake_response(message)
    else
      message_length = Message.parse_message_length(message)
      print "message length #{message_length} "
      msg_id = Message.parse_message_id(message)
      print "message id #{msg_id}"
      payload = Message.parse_payload(message)
      print "payload #{payload}"
    end
  end




end
