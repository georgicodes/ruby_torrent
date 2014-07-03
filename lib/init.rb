require "awesome_print"
require 'net/http'
require 'cgi'
require 'socket'
require 'bencode'
require 'eventmachine'
require 'digest/sha1'
require 'SecureRandom'

require_relative 'ruby_torrent/torrent_file'
require_relative 'ruby_torrent/encoder'
require_relative 'ruby_torrent/file_utility'
require_relative 'ruby_torrent/message'
require_relative 'ruby_torrent/peer'
require_relative 'ruby_torrent/torrent_client'

if __FILE__ == $0
  # torrent_client = Client.new('../files/flagfromserver.torrent')
  torrent_client = TorrentClient.new('../files/karl_marx.torrent')
  # torrent_client = TorrentClient.new('files/flagfromserver.torrent')
  # torrent_client = TorrentClient.new('files/karl_marx.torrent')
  # torrent_client = TorrentClient.new('files/speed_up_torrents.torrent')
  torrent_client.launch!
end