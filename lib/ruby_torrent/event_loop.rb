class Connector < EM::Connection
  def post_init
    s = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00*\x9D\x12\x91\xD3s\xE4\xA6\x90hBjQ\xA8\xFE\x85\x85\xDA\xFE>GK-Rc1Z_8Bd2M0yQEhV1"
    send_data s
  end

  def receive_data(data)
    puts "Received data"
    p data
  end
end

class Client
  PeerAddress = Struct.new(:host, :port)

  def initialize(path=nil)
    if (FileUtility.file_useable?(path))
      @torrent_file = TorrentFile.create_from_file(path)
      puts "MetaInfo created from file #{path}"
    else
      puts "File not useable, exiting."
      return -1
    end
  end

  def connect_to_peers
    EM.connect("112.210.159.14", 51413, Connector)
    # EM.connect("112.210.159.14", 51413, Connector)
  end

  def is_download_complete?
    return @torrent_file.complete
  end

  def run_launch_tasks
    # TODO: refactor file is downloaded part
    # 1. connect to tracker
    tracker_response = connect_to_tracker

    # 2. decode response from tracker
    @peers = extract_peers_from_tracker_response(tracker_response)
    @peer = @peers[8]

    # 3. send handshake message to single peer
    send_handshake_to_single_peer()

    # 4. error check handshake response from peer?
    # TODO: implement? Needs to be done for trackers that give peer dictionary

    # 5. send interested message to peer
  end

  # The length prefix is a four byte big-endian value.
  # The message ID is a single decimal byte.
  # The payload is message dependent.
  def send_interested_message_to_peer
    message_interested = Message::Interested.new
    ap "Interested message #{message_interested.to_s}"
    return message_interested
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
    uri = URI(@torrent_file.announce)
    params = {:info_hash => @torrent_file.info_hash,
              :peer_id => @torrent_file.peer_id,
              :left => @torrent_file.length.to_s
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
    peers.each_byte do |b|
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
    handshake_message = @torrent_file.construct_handshake_message
    EM.connect(@peer.host, @peer.port, Peer, handshake_message)

    # peer.start!
  end

  def launch!
    EM.run do

      run_launch_tasks

      EM.add_periodic_timer(60) do
        if (is_download_complete?)
          EM.stop
        end
      end

    end
  end

end
