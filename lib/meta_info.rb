require "awesome_print"
require 'digest/sha1'
require 'SecureRandom'
require 'encoder'

class MetaInfo

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

  TorrentFile = Struct.new(:length, :path)

  attr_reader :announce, :length, :peer_id, :info_hash

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
      @files << TorrentFile.new(item["length"], item["path"])
    end

    @info_hash = init_sha_info_hash
    @name = info["name"]
    @piece_length = info["piece length"]
    @pieces = info["pieces"]
    @length = info["length"]
    @length ||= calculate_length
  end

  # TODO: should be refactored to own class?
  def construct_handshake_message
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