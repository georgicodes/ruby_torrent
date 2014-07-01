module Message

  class BaseMessage
    LENGTH_PREFIX_NO_PAYLOAD = "\x00\x00\x00\x01"

    def initialize(message_id, payload = nil)
      @message_id = message_id
      @payload = nil
    end

    def to_s
      length_prefix + @message_id
    end

    def length_prefix
      # TODO: count num bytes in payload + 1 OR return LENGTH_PREFIX_NO_PAYLOAD
      return LENGTH_PREFIX_NO_PAYLOAD
    end
  end

  class Interested < BaseMessage
    MSG_ID = 2.chr

    def initialize
      super(MSG_ID)
    end
  end

  class NotInterested < BaseMessage
    MSG_ID = 3.chr

    def initialize
      super(MSG_ID)
    end
  end

  class Have < BaseMessage
    MSG_ID = 4.chr

    def initialize(payload)
      super(MSG_ID, payload)
    end
  end
end
