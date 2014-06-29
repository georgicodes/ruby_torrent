module FileUtility

  def self.file_exists?(path)
    return false unless path
    return false unless File.exist?(path)
    return true
  end

  def self.file_useable?(path)
    return false unless FileUtility.file_exists?(path)
    return false unless File.readable?(path)
    return false unless File.writable?(path)
    return true
  end

  def self.read_contents_from_file(path)
    return "" unless FileUtility.file_useable?(path)

    file_path = File.join(APP_ROOT, path)
    File.read(file_path)
  end


end