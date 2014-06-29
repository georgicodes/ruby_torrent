require "awesome_print"
require 'digest/sha1'
require 'SecureRandom'
require 'encoder'

class MetaInfo
  include Encoder

  TorrentFile = Struct.new(:length, :path)

  attr_reader :announce, :length

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
  end

  def init_info_hash_args(args)
    info_hash = args["info"]

    @files = []
    # TODO implement multi files as they are represented differently
    info_hash["files"].each do |item|
      @files << TorrentFile.new(item["length"], item["path"])
    end

    @name = info_hash["name"]
    @piece_length = info_hash["piece length"]
    @pieces = info_hash["pieces"]
    @length = info_hash["length"]
    @length ||= calculate_length
  end

  def calculate_length
    @files.reduce(0) do |memo, file|
      memo += file.length
    end
  end

  def sha_info_hash
    decoded_info_hash = @decoded_hash["info"]
    encoded_info_hash = Encoder.encode(decoded_info_hash)
    Digest::SHA1.digest encoded_info_hash
  end

  def client_id
    "GK-" + SecureRandom.urlsafe_base64(16).to_s[0...17]
  end

end