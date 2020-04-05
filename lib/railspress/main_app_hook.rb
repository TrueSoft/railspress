module Railspress
  class MainAppHook
    attr_reader :on_show_wp_page

    def initialize
      @on_show_wp_page = []
    end
  end
end