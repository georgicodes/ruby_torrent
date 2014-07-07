require "awesome_print"
require 'net/http'
require 'cgi'
require 'socket'
require 'bencode'
require 'eventmachine'
require 'digest/sha1'
require 'SecureRandom'
require 'colorize'
require 'bitarray'

require_relative 'ruby_torrent/torrent_client'
require_relative 'ruby_torrent/torrent_file'
require_relative 'ruby_torrent/encoder'
require_relative 'ruby_torrent/file_utility'
require_relative 'ruby_torrent/message'
require_relative 'ruby_torrent/peer'
require_relative 'ruby_torrent/buffer_handler'
require_relative 'ruby_torrent/handshake'

APP_ROOT = File.dirname(__FILE__)

# TODO read from argv isntead of hardcoding files
if __FILE__ == $0
  # torrent_file = '../files/karl_marx.torrent'
  # torrent_file = '../files/speed_up_torrents.torrent'
  torrent_file = '../files/flagfromserver.torrent'
  file_path = File.join(APP_ROOT, torrent_file)
  torrent_client = TorrentClient.create_from_files([file_path])
  torrent_client.launch!
end