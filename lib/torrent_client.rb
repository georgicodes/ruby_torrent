require 'meta_info'
require 'encoder'
require 'file_utility'
require 'message'
require 'message_dispatcher'
require "awesome_print"
require 'net/http'
require 'cgi'
require 'socket'

class TorrentClient

  PeerAddress = Struct.new(:host, :port)

  def initialize(path=nil)
    if (FileUtility.file_useable?(path))
      @meta_info = MetaInfo.create_from_file(path)
      puts "MetaInfo created from file #{path}"
    else
      puts "File not useable, exiting."
      return -1
    end
  end

  def launch!
    # 1. connect to tracker
    # 2. decode response from tracker
    # 3. send handshake message to single peer
    # 4. error check handshake response from peer
    # 5. send interested message to peer
    tracker_response = connect_to_tracker
    peers = extract_peers_from_tracker_response(tracker_response)
    @peer = peers[1]
    handshake_response = send_handshake_to_single_peer()
    # verify_handshake_response(handshake_response) # TODO: implement?
    send_interested_message_to_peer
  end

  # <length prefix><message ID><payload>.
  # The length prefix is a four byte big-endian value.
  # The message ID is a single decimal byte.
  # The payload is message dependent.
  def send_interested_message_to_peer
    message_interested = Message::Interested.new
    ap "Interested message #{message_interested.to_s}"
    client = MessageDispatcher::Client.new(@peer.host, @peer.port)
    client.request(message_interested.to_s)
  end

  def connect_to_tracker
    # connect via HTTP to tracker
    # tracker hold info about torrent and peers
    # will respond to get request with list of peers
    # PARAMS
    # info_hash -> Compute SHA1 hash on bencoded info dict ONLY. ensure order is preserved
    # peer_id -> anything that is 20 bytest long
    # left -> for first time should be total length of file.
    uri = build_tracker_request_uri
    res = Net::HTTP.get_response(uri)

    if (res.is_a?(Net::HTTPSuccess))
      return res.body
    else
      puts "Cannot connect to torrent tracker."
      return -1
    end
  end

  def build_tracker_request_uri
    uri = URI(@meta_info.announce)
    params = {:info_hash => @meta_info.info_hash,
              :peer_id => @meta_info.peer_id,
              :left => @meta_info.length.to_s
    }
    uri.query = URI.encode_www_form(params)
    puts "Tracker URI is: #{uri}"
    return uri
  end

  # peers: (binary model) Instead of using the dictionary model described above,
  # the peers value may be a string consisting of multiples of 6 bytes.
  # First 4 bytes are the IP address and last 2 bytes are the port number.
  # All in network (big endian) notation.
  #TODO: refactor, smaller and should this be all in one class?
  def extract_peers_from_tracker_response(tracker_response)
    peers_hash = Encoder.decode(tracker_response)
    peers = peers_hash["peers"]
    num_hosts = peers_hash["complete"] + peers_hash["incomplete"]

    peers_array = []
    peers.each_byte do|b|
      peers_array << b
    end

    ip_addresses = []
    num_hosts.times {
      ip_address = peers_array.shift(4).join(".")
      port = (peers_array.shift * 256) + peers_array.shift
      ip_addresses << PeerAddress.new(ip_address.to_s, port)
    }
    return ip_addresses
  end

  def send_handshake_to_single_peer()
    puts "======= opening socket on: #{@peer.host}:#{@peer.port} ========"
    client_socket = TCPSocket.new(@peer.host, @peer.port)
    puts "======= opened socket ========"

    handshake_message = @meta_info.construct_handshake_message
    puts "======= sending message ========"
    puts handshake_message.inspect
    client_socket.write(handshake_message)
    client_socket.close_write # Send EOF after writing the request.

    response = client_socket.read # Read until EOF to get the response.
    puts "======= response received ========"
    puts response.inspect
    if (!response.nil?)
      return -1
    end

    return response
  end

end