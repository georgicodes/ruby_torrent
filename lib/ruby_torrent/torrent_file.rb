class TorrentFile

  #TODO: refactor this into own class? perhaps a message type class?
  # handshake: <pstrlen><pstr><reserved><info><peer_id>
  #
  # pstrlen: string length of <pstr>, as a single raw byte
  # pstr: string identifier of the protocol
  # reserved: eight (8) reserved bytes. All current implementations use all zeroes.
  # info_hash: 20-byte SHA1 hash of the info key in the metainfo file.
  #    This is the same info_hash that is transmitted in tracker requests.
  # peer_id: 20-byte string used as a unique ID for the client.
  #    This is usually the same peer_id that is transmitted in tracker requests
  HANDSHAKE_PSTRLEN = 19.chr
  HANDSHAKE_PSTR = "BitTorrent protocol"
  HANDSHAKE_RESERVED = "\x00\x00\x00\x00\x00\x00\x00\x00"

  FileToDownload = Struct.new(:length, :path)
  PeerAddress = Struct.new(:host, :port)

  attr_reader :announce, :length, :peer_id, :info_hash, :complete

  def self.create_from_file(path=nil)
    encoded_file_contents = FileUtility.read_contents_from_file(path)
    decoded_hash = Encoder.decode(encoded_file_contents)
    return self.new(decoded_hash)
  end

  def initialize(args)
    @decoded_hash = args

    init_base_args(args)
    init_info_hash_args(args)
  end

  def init_base_args(args)
    @complete = false
    @announce = args["announce"]
    @locale = args["locale"]
    @title = args["title"]
    @comment = args["comment"]
    @creation_date = args["creation date"]
    @peer_id = init_peer_id
  end

  def init_info_hash_args(args)
    info = args["info"]

    @files = []
    # TODO implement multi files as they are represented differently
    info["files"].each do |item|
      @files << FileToDownload.new(item["length"], item["path"])
    end

    @info_hash = init_sha_info_hash
    @name = info["name"]
    @piece_length = info["piece length"]
    @pieces = info["pieces"]
    @length = info["length"]
    @length ||= calculate_length
  end

  def connect_with_tracker_and_peers
    tracker_response = connect_to_tracker
    @peers = init_peers(tracker_response)
    send_handshake_to_peers
  end

  #TODO: Event Machine for HTTP get?
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
    uri = URI(@announce)
    params = {:info_hash => @info_hash,
              :peer_id => @peer_id,
              :left => @length.to_s
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
  def init_peers(tracker_response)
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

  def send_handshake_to_peers
    @peers.each do |peer|
      begin
        puts "peer host #{peer.host}:#{peer.port} "
        EM.connect(peer.host, peer.port, Peer, peer.host, peer.port, handshake_message)
      rescue EventMachine::ConnectionError
        puts "error connecting to peer #{peer.host}:#{peer.port}"
      end
    end
  end

  # TODO: should be refactored to own class?
  # The length prefix is a four byte big-endian value.
  # The message ID is a single decimal byte.
  # The payload is message dependent.
  def handshake_message
    HANDSHAKE_PSTRLEN + HANDSHAKE_PSTR + HANDSHAKE_RESERVED + info_hash + peer_id
  end

  private
  def calculate_length
    @files.reduce(0) do |memo, file|
      memo += file.length
    end
  end

  def init_sha_info_hash
    encoded_info_hash = encode(@decoded_hash["info"])
    Digest::SHA1.digest encoded_info_hash
  end

  def encode(decoded_info_hash)
    Encoder.encode(decoded_info_hash)
  end

  def init_peer_id
    "GK-" + SecureRandom.urlsafe_base64(16).to_s[0...17]
  end

end