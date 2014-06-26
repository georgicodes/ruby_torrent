require 'meta_info'
require 'bencode'
require "awesome_print"
require 'net/http'
require 'addressable/uri'
require 'cgi'
require 'logger'

class TorrentClient

  def initialize(path=nil)
    # TODO: add class methods to tracker and proper error handling
    # MetaInfo.filepath = path
    # puts "Tracker file: #{path}"
    @meta_info = MetaInfo.create_from_file(path)
  end

  def launch!
    response = connect_to_tracker

  end

  # TODO: refactor
  def connect_to_tracker
    # connect via HTTP to tracker
    # tracker hold info about torrent and peers
    # will respond to get request with list of peers
    # PARAMS
    # info_hash -> Compute SHA1 hash on bencoded info dict ONLY. ensure order is preserved
    # peer_id -> anything that is 20 bytest long
    # left -> for first time should be total length of file.
    puts "Announce URL: #{@meta_info.announce}"
    puts @meta_info.compute_hash_on_info
    puts "Info Hash: #{@meta_info.compute_hash_on_info}"
    puts @meta_info.client_id
    puts "Client Id: #{@meta_info.client_id}"
    puts @meta_info.length
    puts "Length: #{@meta_info.length}"

    uri = URI(@meta_info.announce)
    params = {:info_hash => @meta_info.compute_hash_on_info,
              :peer_id => @meta_info.client_id,
              :left => @meta_info.length.to_s
    }
    uri.query = URI.encode_www_form(params)
    puts "Tracker URI is: #{uri}"
    res = Net::HTTP.get_response(uri)
    puts "$$$$$$$$$$$$$$$$$"
    puts "#{res}"

    raise "Error from tracker" unless res.is_a?(Net::HTTPSuccess)
    return res.body
  end



end