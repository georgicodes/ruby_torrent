require 'meta_info'
require "awesome_print"
require 'net/http'
require 'cgi'
require 'encoder'
require 'file_utility'

class TorrentClient
  include Encoder
  include FileUtility

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
    Encoder.decode(tracker_response)
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

end