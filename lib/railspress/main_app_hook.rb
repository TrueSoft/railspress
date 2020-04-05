module Railspress
  class MainAppHook
    # for the :show_page event
    attr_reader :on_show_wp_page
    # for the :signed_in? event
    attr_accessor :on_check_signed_in

    def initialize
      @on_show_wp_page = []
      @on_check_signed_in = nil
    end
  end
end