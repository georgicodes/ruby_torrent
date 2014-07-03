class TorrentClient

  def initialize(path=nil)
    if (FileUtility.file_useable?(path))
      @torrent_file = TorrentFile.create_from_file(path)
      puts "MetaInfo created from file #{path}"
    else
      puts "File not useable, exiting."
      return -1
    end
  end

  def is_download_complete?
    return @torrent_file.complete
  end

  def launch!
    EM.run do

      @torrent_file.connect_with_tracker_and_peers

      EM.add_periodic_timer(60) do
        if (is_download_complete?)
          EM.stop
        end
      end

    end
  end

end
