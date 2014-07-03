class Peer < EM::Connection

  def initialize(host, port, handshake)
    @host = host
    @port = port
    @handshake = handshake
  end

  def post_init
    send_data(@handshake)
  end

  def receive_data(data)
    puts "Received data on #{@host}:#{@port}"
    p data
  end

  # def get_handshake_response
  #   pstrlen = @connection.getbyte
  #   @handshake_respone = {
  #     :pstrlen => pstrlen,
  #     :pstr => @connection.read(pstrlen),
  #     :reserved => @connection.read(8),
  #     :info_hash => @connection.read(20),
  #     :peer_id => @connection.read(20)
  #   }
  #   puts "======= received handshake ========"
  #   ap @handshake_respone
  # end

end