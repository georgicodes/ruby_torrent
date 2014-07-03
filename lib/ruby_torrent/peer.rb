class Peer < EM::Connection

  def initialize(handshake)
    @handshake = handshake

    # init_socket
    # init_handshake(handshake)
    # init_fiber
  end

  def post_init
    send_data(@handshake)
  end

  def receive_data(data)
    puts "Received data"
    p data
  end

  def init_socket
    puts "======= opening socket on: #{@host}:#{@port} ========"
    @connection = TCPSocket.new(@host, @port)
    puts "======= opened socket ========"
  end

  def init_handshake(handshake)
    send_handshake(handshake)
    get_handshake_response()
  end

  def get_handshake_response
    pstrlen = @connection.getbyte
    @handshake_respone = {
      :pstrlen => pstrlen,
      :pstr => @connection.read(pstrlen),
      :reserved => @connection.read(8),
      :info_hash => @connection.read(20),
      :peer_id => @connection.read(20)
    }
    puts "======= received handshake ========"
    ap @handshake_respone
  end

  def send_handshake(handshake)
    puts "======= sending handshake ========"
    p handshake
    @connection.write(handshake)
  end

  def send_message(message)
    puts "======= sending message ========"
    p message
    @connection.write(message)
    get_response
  end

  def init_fiber
    @fiber = Fiber.new do |byte|
      byte_count = 0
      msg_size = 0
      msg_id = nil
      payload = ''

      loop do
        byte_count += 1

        if (byte_count <= 4)
          msg_size += byte.ord
          puts "Current byte_count: #{byte_count} & msg size #{msg_size}"
        elsif (byte_count == 5)
          msg_id = byte.ord
          puts "Current byte_count: #{byte_count} & msg size #{msg_size} & Message Id: #{msg_id}"
        elsif (payload.length == (msg_size -1)) # reached end of message
          Fiber.yield msg_id
        end

        # put yield at end of loop so it runs through for first value
        # we need to reset the byte variable here because subsequent calls to resume will come here
        byte = Fiber.yield
      end
    end
  end

  def get_response
    puts "======= receiving message ========"

    full_message = nil
    until !full_message.nil?
      byte = @connection.read(1)
      p byte
      full_message = @fiber.resume byte
    end
    p full_message
  end

  def get_a_message
    # just sit here blocking and reading until we parse a full message, then return it
  end

  def start!
    Thread.new { keep_alive }
    # keep_alive
    send_message(Message::Interested.new.to_s)
  end

  def keep_alive
    loop do
      puts "in keep alive"
      sleep(60)
      @connection.write("\x00\x00\x00\x00")
      puts "here"
    end
  end
end