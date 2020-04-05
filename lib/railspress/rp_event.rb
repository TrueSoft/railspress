module Railspress
  class RpEvent
    attr_accessor :temp_message

    def on(event_type, event_obj)
      true
    end
  end
end
