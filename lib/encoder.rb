require 'bencode'
require "awesome_print"

module Encoder

  def self.decode(data)
    decoded = BEncode.load(data)
    puts "Decoded result =>"
    ap decoded
  end

  def self.encode(data)
    encoded = data.bencode
    puts "Encoded result =>"
    ap encoded
  end

end