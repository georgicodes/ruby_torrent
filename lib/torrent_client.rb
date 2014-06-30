require 'meta_info'
require "awesome_print"
require 'net/http'
require 'cgi'
require 'encoder'
require 'file_utility'
require 'socket'

class TorrentClient
  include Encoder
  include FileUtility

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
    # connect to tracker
    # decode response from tracker
    tracker_response = connect_to_tracker
    extract_hosts_from_tracker_response(tracker_response)
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
    params = {:info_hash => @meta_info.sha_info_hash,
              :peer_id => @meta_info.client_id,
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

  # This involves changing the peer string from unicode (binary model)
  # to a network(?) model(x.x.x.x:y). From the spec: 'First 4 bytes are the IP address and
  # last 2 bytes are the port number'
  def extract_hosts_from_tracker_response(tracker_response)
    peers_hash = Encoder.decode(tracker_response)
    peers = peers_hash["peers"]
    num_hosts = peers_hash["complete"] + peers_hash["incomplete"]
    ap peers

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
    puts ip_addresses

    client_socket = TCPSocket.new(ip_addresses[0].host, ip_addresses[0].port)
    client_socket.write("not the right message")
    client_socket.close_write # Send EOF after writing the request.

    puts client_socket.read # Read until EOF to get the response.
  end


end