require 'meta_info'
require 'bencode'
require "awesome_print"
require 'net/http'
require 'cgi'

class TorrentClient

  def initialize(path=nil)
    # TODO: add class methods to tracker and proper error handling
    # MetaInfo.filepath = path
    # puts "Tracker file: #{path}"
    @meta_info = MetaInfo.create_from_file(path)
    puts @meta_info.inspect
  end

  def launch!
    connect_to_tracker
  end

  def connect_to_tracker
    # connect via HTTP to tracker
    # tracker hold info about torrent and peers
    # will respond to get request with list of peers
    # PARAMS
    # info_hash -> Compute SHA1 hash on bencoded info dict ONLY. ensure order is preserved
    # peer_id -> anything that is 20 bytest long
    # left -> for first time should be total length of file.
    puts @meta_info.compute_hash_on_info
    puts @meta_info.client_id
    puts @meta_info.length
  end

  def make_request_to_tracker
    uri = URI(@meta_info.announce)
    params = {:info_hash => @meta_info.compute_hash_on_info,
              :peer_id => @meta_info.client_id,
              :left => @meta_info.length
    }
    uri.query = URI.encode_www_form(CGI::escape(params))

    res = Net::HTTP.get_response(uri)
    puts res.body if res.is_a?(Net::HTTPSuccess)
  end


end