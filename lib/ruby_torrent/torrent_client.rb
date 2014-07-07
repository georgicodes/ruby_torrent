class TorrentClient

  attr_accessor :torrent_files

  def self.create_from_files(torrent_file_paths)
    torrent_files = []
    torrent_file_paths.each do |path|
      if (FileUtility.file_useable?(path))
        puts "Torrent meta info created from file #{path}"
        torrent_file = TorrentFile.create_from_file(path)
        torrent_files << torrent_file
      end
    end

    if (torrent_files.length == 0)
      puts "File not useable, exiting."
      raise ArgumentError
    end

    self.new(torrent_files)
  end

  def initialize(torrent_files)
    @torrent_files = torrent_files
  end

  def are_all_file_downloads_complete
    return @torrent_files.first.complete
  end

  def launch!
    EM.run do

      # TODO accommodate multiple torrent files
      @torrent_files.first.launch!

      EM.add_periodic_timer(60) do
        if (are_all_file_downloads_complete)
          EM.stop
        end
      end

    end
  end

end
