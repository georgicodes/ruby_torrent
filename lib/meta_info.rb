require "awesome_print"
require 'digest/sha1'
require 'SecureRandom'

class MetaInfo

  attr_reader :announce, :encoded, :length

  def initialize(encoded_contents, args)
    # refactor this constructor
    @encoded = encoded_contents
    @decoded_hash = args
    init_base_args(args)
    init_info_hash_args(args)
  end

  def init_info_hash_args(args)
    info_hash = args["info"]
    @name = info_hash["name"]
    @piece_length = info_hash["piece length"]
    @length = info_hash["length"]

    # TODO implement multi files as they are represented differently
    @pieces = info_hash["pieces"]
  end

  def init_base_args(args)
    @announce = args["announce"]
    @locale = args["locale"]
    @title = args["title"]
    @comment = args["comment"]
    @creation_date = args["creation date"]
  end

  def self.create_from_file(path=nil)
    encoded_contents = read_contents_from_file(path)
    meta_info_hash = decode(encoded_contents)
    ap meta_info_hash
    return self.new(encoded_contents, meta_info_hash)
  end

  def self.decode(data)
    BEncode.load(data)
  end

  def self.encode(data)
    data.bencode
  end

  def self.read_contents_from_file(path)
    # TODO: if file doesn't exist etc.
    file_path = File.join(APP_ROOT, path)
    File.read(file_path)
  end

  def compute_hash_on_info
    #TODO refacotr method
    decoded_info_hash = @decoded_hash["info"]
    encoded_info_hash = MetaInfo.encode(decoded_info_hash)
    Digest::SHA1.base64digest encoded_info_hash
  end

  def client_id
    "GK-" + SecureRandom.urlsafe_base64(17)
  end

end