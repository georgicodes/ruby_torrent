class Peer < EM::Connection

  BLOCK_SIZE = 14**2

  attr_writer :peer_interested, :host, :port, :handshake
  attr_accessor :torrent_file

  def initialize
    @am_choking = true
    @am_interested = false
    @peer_choking = true
    @peer_interested = false # false when remote peer is not interested in requesting blocks from this client

    @buff_handler = BufferHandler.new

    @current_piece_index = 0
    @current_piece_offset = 0
    @current_piece_offset_index = 0
    @current_piece_buffer_size = 0
    @current_piece_buffer = ""
    @downloaded_size = 0
    # @piece_handler = PieceHandler.new(@torrent_file)
  end

  # TODO should this handshake logic be moved until connection is 100% established?
  def connection_completed
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

    case torrent_message
      when HandshakeMessage
        handle_handshake_message(torrent_message)
      when ChokeMessage
        @peer_choking = true
      when UnchokeMessage
        @peer_choking = false
        puts "Peer no longer choking, may request blocks"
        msg = process_block_request
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
        handle_piece_message(torrent_message)
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
    @handshake_response = {
        :pstrlen => pstrlen,
        :pstr => stream.read(pstrlen),
        :reserved => stream.read(8),
        :info_hash => stream.read(20),
        :peer_id => stream.read(20)
    }
    puts "Handshake response received."
    ap @handshake_response
  end

  def handle_piece_message(piece_message)
    @current_piece_buffer += piece_message.block_data
    @current_piece_buffer_size += piece_message.block_data.size #TODO can we remove this?
    @downloaded_size += piece_message.block_data.size
    puts "Total downloaded size so far is: #{@downloaded_size.to_s}"
    puts "Currently processing piece #{@current_piece_index}, block #{@current_piece_offset_index}, block offset #{@current_piece_offset}"
    puts "There are #{num_blocks_per_piece} blocks per piece."
    ap @torrent_file.summary

    if (@downloaded_size == total_length)
      puts "Writing to file"
      @torrent_file.write_to_file
      return
    end

    # prepare values for next request
    @current_piece_offset += BLOCK_SIZE
    @current_piece_offset_index += 1

    # length of final block will be smaller than BLOCKSIZE
    if (@current_piece_offset_index == (num_blocks_per_piece - 1))
      puts("&&&&&&&&&&&&&&&&&&&&&&&&&&&  LAST BLOCK  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&")
      block_size = piece_length - @current_piece_buffer_size
      puts "Last block in piece, requesting block_size #{block_size}"

      msg = process_block_request(block_size)
      send_message(msg)
      return
    end

    if (@current_piece_buffer_size == piece_length)
      puts("&&&&&&&&&&&&&&&&&&&&&&&&&&&  FULL PIECE  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&")
      puts "Piece #{@current_piece_index} has been downloaded"

      @torrent_file.file_buffer[@current_piece_index] = @current_piece_buffer
      @torrent_file.write_block(@current_piece_index, @current_piece_buffer)
      @current_piece_index += 1 # increment piece index
      @current_piece_offset = 0 # reset piece offset
      @current_piece_offset_index = 0
      @current_piece_buffer_size = 0
      puts "New piece index #{@current_piece_index}"
    end

    # final block of final piece
    if (@current_piece_index == (num_pieces - 1))
      puts "Final request?"

      block_size = total_length - @downloaded_size
      msg = process_block_request(block_size)
      send_message(msg)
      return
    end

    msg = process_block_request
    send_message(msg)
  end

  def process_block_request(block_size=BLOCK_SIZE)
    args = {}
    args[:piece_index] = @current_piece_index
    args[:byte_offset] = @current_piece_offset
    args[:block_length] = block_size

    request_message = RequestMessage.new(args)
    ap request_message.summary
    request_message.formatted_message
  end

  def num_blocks_per_piece
    (@torrent_file.piece_length.to_f / BLOCK_SIZE).ceil
  end

  def num_full_blocks
    num_blocks_per_piece - 1
  end

  def piece_length
    @torrent_file.piece_length
  end

  def num_pieces
    @torrent_file.num_pieces
  end

  def total_length
    @torrent_file.length
  end
end
