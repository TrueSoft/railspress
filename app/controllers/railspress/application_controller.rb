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
      if Railspress.multi_language
        parsed_locale = params[:language] || I18n.default_locale
        I18n.locale = I18n.available_locales.include?(parsed_locale.to_sym) ? parsed_locale  : I18n.default_locale
        params[:language] = I18n.locale.to_s
      end
    end

    def init_wp_query
      require_relative '../../../lib/railspress/wp_query'
      @wp_query = Railspress::WP_Query.new params
    end

    protected

    # Next is the code from template-loader.php
    def determine_templates
      if @wp_query.is_front_page?
        get_front_page_template
      elsif @wp_query.is_home
        get_home_template
      elsif @wp_query.is_privacy_policy
        get_privacy_policy_template
      elsif @wp_query.is_post_type_archive?
        get_post_type_archive_template
      elsif @wp_query.is_tax
        get_taxonomy_template
      elsif @wp_query.is_attachment
        get_attachment_template
      elsif @wp_query.is_single
        get_single_template
      elsif @wp_query.is_page
        get_page_template
      elsif @wp_query.is_singular
        get_singular_template
      elsif @wp_query.is_category
        get_category_template
      elsif @wp_query.is_tag
        get_tag_template
      elsif @wp_query.is_author
        get_author_template
      elsif @wp_query.is_date
        get_date_template
      elsif @wp_query.is_archive
        get_archive_template
      else
        []
      end
    end

    def default_filter
      if Railspress.multi_language
        parsed_locale = params[:language] || I18n.default_locale
        tt_id = Railspress::Language.joins(:term).where(Railspress::Term.table_name => {slug: parsed_locale}).pluck(:term_taxonomy_id)
        {Railspress::Taxonomy.table_name => {term_id: tt_id.empty? ? 0 : tt_id.first }}
      else
        {}
      end
    end
  end
end
