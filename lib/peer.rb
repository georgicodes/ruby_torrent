require 'message'
require "awesome_print"

class Peer
  def initialize(host, port, handshake)
    @host = host
    @port = port

    init_socket
    init_handshake(handshake)
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
    response = @connection.read
    p response
  end

  def send_handshake(handshake)
    puts "======= sending message ========"
    p handshake
    @connection.write(handshake)
  end

  def send_message(message)
    puts "======= sending message ========"
    p message
    @connection.write(message)
    get_response
  end

  def get_response
    puts "======= response received ========"
    # response = @connection.readbyte
    # ap response
    # emulates blocking read (readpartial).
    while data = @connection.read(1) do
      p data
    end
    return data
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