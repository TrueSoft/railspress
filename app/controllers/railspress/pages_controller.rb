require_dependency "railspress/application_controller"

module Railspress
  class PagesController < ApplicationController
    include Railspress::TemplateHelper

    def index
      @page = @wp_query.get_queried_object
      unless @page.nil?
        if @page.post_status == 'private'
          event_check_si = Railspress.main_app_hook.on_check_signed_in
          if !event_check_si.nil? && !event_check_si.on(:signed_in?, @page, session)
            redirect_to main_app.root_path, alert: t('railspress.pages.show.no_public', slug: params[:pagename])
            return
          end
        end
        orig_page_id = @page.id
        if Railspress.multi_language
          # ---- Get the translated version if it is the case
          @page = helpers.get_translated_page @page, params[:language] || I18n.default_locale.to_s
          if orig_page_id != @page.id
            parsed_locale = params[:language] || I18n.default_locale.to_s
            logger.info "Redirecting to translated version (#{@page.post_name}/#{parsed_locale})"
            redirect_to show_page_path(helpers.get_page_uri(@page), language: parsed_locale == I18n.default_locale.to_s ? nil : params[:language])  # TODO de verificat
            return
          end
        end
        @is_revision = params[:rev] && params[:token] == helpers.ts_token(params[:rev])
        if @is_revision
          rev = helpers.wp_get_post_revisions(@page.id, include: params[:rev])
          if rev.blank?
            @is_revision = false
          else
            @main_post = @page
            @page = rev.values.first
          end
        end
        if @is_revision
          @revision_post_date_title_format = '%B %Y'
          prdtf = @main_post.metas.select { |meta|  meta.meta_key == 'revision_post_date_title_format' }
          @revision_post_date_title_format = prdtf.first.meta_value unless prdtf.empty?
        end
        unless @is_revision
          if Railspress.generate_breadcrumb
            has_breadcrumb = (@page.metas.select {|meta| meta.meta_key == 'breadcrumb' and meta.meta_value == '0'}.empty?)
            if has_breadcrumb
              @breadcrumb = {}
              ancestors.each do |page|
                @breadcrumb[page.post_title] = main_app.show_page_path(helpers.get_page_uri(page))
              end
            end
          end
        end
        Railspress.main_app_hook.on_show_wp_page.each do |event|
          unless event.on(:show_page, @page, session)
            redirect_to main_app.root_path, alert: (event.temp_message || t('railspress.pages.show.not_allowed', slug: params[:pagename]))
            return
          end
        end
        if Railspress.multi_language
          @latest_posts = Railspress::Post.published.descending.joins(:languages).where(default_filter).first(2)
        else
          @latest_posts = Railspress::Post.published.descending.where(default_filter).first(2)
        end
        @post_class = @page.metas.select {|meta| meta.meta_key == 'post-class'}.map {|meta| meta.meta_value}.first
        # Next is the code from template-loader.php
        templates = if @wp_query.is_front_page?
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
        templates.each do |tmpl|
          begin
            tmpl = tmpl.gsub(/\.php$/, '')
            render action: tmpl
            return
          rescue ActionView::MissingTemplate
            next
          end
        end
        render action: :index # if no other template was found until now
      end
    end

    def test
      
    end

    private

    def init_wp_query
      # post_type
      # args.kind_of? ActionController::Parameters
      params_as_hash = JSON.parse(params.to_s.gsub('=>', ':'))
      super
      # @wp_query = Railspress::WP_Query.new params_as_hash
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
