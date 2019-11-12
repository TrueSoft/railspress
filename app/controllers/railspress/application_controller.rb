module Railspress
  class ApplicationController < ::ApplicationController
    protect_from_forgery with: :exception

    before_action :set_app_language
    before_action :init_wp_query

    private

    # def default_url_options
    #   { language: I18n.locale == I18n.default_locale ? nil : I18n.locale }
    # end

    def set_app_language
      parsed_locale = params[:language] || I18n.default_locale
      I18n.locale = I18n.available_locales.include?(parsed_locale.to_sym) ? parsed_locale  : I18n.default_locale
      params[:language] = I18n.locale.to_s
    end

    def init_wp_query
      @wp_query = Railspress::WP_Query.new
      p "App init_wp_query Railspress::WP_Query.new = #{@wp_query}"
    end
  end
end
