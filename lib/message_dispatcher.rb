module MessageDispatcher

  class Client
    class << self

    end
    def initialize(host, port)
      @host = host
      @port = port
    end

    def request(message)
      @client = TCPSocket.new(@host, @port)
      ap "created a client with host #{@host} and port #{@port}"
      @client.write(message)
      @client.close_write # Send EOF after writing the request.
      ap "sent message #{message}"

      while line = @client.gets # Read lines from socket
        ap line         # and print them
      end
      # response = @client.read # Read until EOF to get the response.
      # ap response
    end
  end
end