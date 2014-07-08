class PieceHandler

  BLOCK_SIZE = 14**2

  def initialize(args)
    # @torrent_file = args[:torrent_file]
    # @piece_length = @torrent_file.
    # @piece_hashes = args[:pieces]
    # @pieces_received
    @num_pieces = args[:num_pieces]
    @piece_length = args[:piece_length]
  end

  def num_blocks_per_piece
    (@num_pieces / BLOCK_SIZE).ceil
  end

  def num_full_blocks_per_piece
    num_blocks_per_piece - 1
  end

  def request_next_block

  end

end