require 'fiber'

end_fiber = Fiber.new do |frame|
  puts "TRANSFERED"
  # Fiber.yield
end


fiber = Fiber.new do |byte|
  byte_count = 0
  buffer = ''
  msg_size = 0
  msg_id = nil
  payload = ''

  loop do
    byte_count += 1
    # curr_value = byte
    # buffer += curr_value

    # puts frame.class
    # puts frame.to_i

    # puts "Current value: #{byte}"
    puts "Current byte_count: #{byte_count}"
    # puts "Current frame length: #{frame.length}"
    # puts "msg size #{msg_size}"
    # puts frame.class

    if (byte_count <= 4)
      msg_size += byte.ord
      # puts "msg size #{msg_size}"
    elsif (byte_count == 5)
      # puts "msg size #{msg_size}"
      msg_id = byte.ord
      # p byte
    end

    # if (payload.length == (msg_size -1)) # reached end of message
    #   Fiber.yield msg_id
    # end
    # elsif (buffer.length == msg_size)
    # end

    # put yield at end of loop so it runs through for first value
    # we need to reset the byte variable here because subsequent calls to resume will come here
    byte = Fiber.yield
  end
end

def max_length_for_message(msg_id)
  return 1
end

"\x00\x00\x00\x01\x02\x00".each_byte do |byte|
  # p "sending byte #{byte}"
  result = nil
  result = fiber.resume byte
  if (!result.nil?)
    p result
    break
  end
end

# fiber2 = Fiber.new do |input|
#   loop do
#     puts input
#     input = Fiber.yield
#   end
# end
#
# "hello".each_char do |i|
#   fiber2.resume i
# end
