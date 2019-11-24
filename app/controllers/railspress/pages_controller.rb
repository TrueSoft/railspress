require_dependency "railspress/application_controller"

module Railspress
  class PagesController < ApplicationController
    def home
      if 'page' == helpers.get_option('show_on_front')
        home_page_id = helpers.get_option('page_on_front')
        unless home_page_id.blank?
          @page = Railspress::Page.where(post_type: 'page', id: home_page_id, post_status: 'publish').first
          if Railspress.multi_language
            # ---- Get the translated version if it is the case
            @page = helpers.get_translated_page @page, params[:language] || I18n.default_locale.to_s
          end
        end
      end
      if Railspress.multi_language
        @latest_posts = Railspress::Post.published.descending.joins(:languages).where(default_filter).first(2)
      else
        @latest_posts = Railspress::Post.published.descending.where(default_filter).first(2)
      end
    end

    def show
      slugs = params[:slug].split('/')
      ancestors = []
      begin
        post_parent = 0
        slugs.each do |slug|
          @page = Railspress::Page.where(post_name: slug, post_parent: post_parent).first!
          post_parent = @page.id
          ancestors << @page
        end
      rescue ActiveRecord::RecordNotFound
        # retry
        if slugs.size == 1
          @page = Railspress::Page.where(post_name: params[:slug]).first
          redirect_to main_app.root_path, alert: t('railspress.pages.show.not_found', slug: params[:slug]) if @page.nil?
        else
          redirect_to main_app.root_path, alert: t('railspress.pages.show.not_found', slug: params[:slug])
          @page = nil
        end
      end
      unless @page.nil?
        if @page.post_status == 'private' && !user_signed_in?
          redirect_to main_app.root_path, alert: t('railspress.pages.show.no_public', slug: params[:slug])
          return
        end
        orig_page_id = @page.id
        if Railspress.multi_language
          @page = helpers.get_translated_page @page, params[:language] || I18n.default_locale.to_s
          if orig_page_id != @page.id
            parsed_locale = params[:language] || I18n.default_locale.to_s
            logger.info "Redirecting to translated version (#{@page.post_name}/#{parsed_locale})"
            redirect_to show_page_path(helpers.get_page_uri(@page), language: parsed_locale == I18n.default_locale.to_s ? nil : params[:language])
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
        @post_class = @page.metas.select { |meta|  meta.meta_key == 'post-class' }.map { |meta| meta.meta_value}.first
      end
    end

    def test
      
    end

    private

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
