require_dependency "railspress/application_controller"

module Railspress
  class PostsController < ApplicationController
    include Railspress::TemplateHelper

    def singular
      # @wp_query = Railspress::WP_Query.new(params)
      @post = @wp_query.post # Railspress::Post.published.where(post_name: params[:name]).first!
      unless @post.nil?
        if @post.post_status == 'private'
          event_check_si = Railspress.main_app_hook.on_check_signed_in
          if !event_check_si.nil? && !event_check_si.on(:signed_in?, @post, session)
            redirect_to main_app.root_path, alert: t('railspress.pages.show.no_public', slug: params[:pagename])
            return
          end
        end
        orig_page_id = @post.id
        @post = helpers.get_translated_page @post, params[:language] || I18n.default_locale.to_s
        if orig_page_id != @post.id
          parsed_locale = params[:language] || I18n.default_locale.to_s
          logger.info "Redirecting to translated version (#{@post.post_name}/#{parsed_locale})"
          redirect_to railspress_engine.show_page_path(helpers.get_page_uri(@post), language: parsed_locale == I18n.default_locale.to_s ? nil : params[:language])
          return
        end
        @is_revision = params[:rev] && params[:token] == helpers.ts_token(params[:rev])
        if @is_revision
          rev = helpers.wp_get_post_revisions(@post.id, include: params[:rev])
          if rev.blank?
            @is_revision = false
          else
            @main_post = @post
            @post = rev.values.first
          end
        end
        if @is_revision
          @revision_post_date_title_format = '%B %Y'
          prdtf = @main_post.metas.select { |meta|  meta.meta_key == 'revision_post_date_title_format' }
          @revision_post_date_title_format = prdtf.first.meta_value unless prdtf.empty?
        end
        @post_class = @post.metas.select { |meta|  meta.meta_key == 'post-class' }.map { |meta| meta.meta_value}.first
      end
      @post_prev, @post_next = neighbours(@post)
      if Railspress.generate_breadcrumb
        if @post.post_type == 'post'
          @breadcrumb[t('railspress.home.posts.title')] = railspress_engine.all_posts_path
          @breadcrumb[@post.post_date.year] = railspress_engine.year_archive_posts_path(year: @post.post_date.year) unless @post.post_date.year == Date.current.year
          @breadcrumb[@post.post_title] = nil
        else
          # unless @is_revision
          #   has_breadcrumb = (@post.metas.select { |meta|  meta.meta_key == 'breadcrumb' and meta.meta_value == '0' }.empty?)
          #   if has_breadcrumb
          ancestors = []
          post_parent = 0
          slugs = params[:slug].nil? ? [] : params[:slug].split('/')
          if slugs.length > 1
            slugs.each do |slug|
              page = Railspress::Page.where(post_name: slug, post_parent: post_parent).first!
              post_parent = page.id
              ancestors << page
            end
            ancestors.each do |page|
              @breadcrumb[page.post_title] = railspress_engine.show_page_path(helpers.get_page_uri(page))
            end
          end
          #   end
          # end
        end
      end
      Railspress.main_app_hook.on_show_wp_page.each do |event|
        unless event.on(:show_page, @post, session)
          redirect_to main_app.root_path, alert: (event.temp_message || t('railspress.pages.show.not_allowed', slug: params[:pagename]))
          return
        end
      end
      templates = determine_templates
      logger.debug "TS_DEBUG: There are #{templates.length} possible templates: #{templates.to_s}" if Railspress.WP_DEBUG
      templates.each do |tmpl|
        begin
          tmpl = tmpl.gsub(/\.php$/, '') # Remove '.php' if necessary
          render action: tmpl
          return
        rescue ActionView::MissingTemplate
          next
        end
      end
      render action: :singular # if no other template was found until now
    rescue ActiveRecord::RecordNotFound
      redirect_to main_app.root_path, alert: t('railspress.post.show.not_found', slug: params[:name])
    end

    private

    def init_wp_query
      # post_type
      # args.kind_of? ActionController::Parameters
      params_as_hash = JSON.parse(params.to_s.gsub('=>', ':'))

      # @wp_query = Railspress::WP_Query.new
      super
    end

    def neighbours(post)
      if post.post_type == 'post'
        if Railspress.multi_language
          [
            Railspress::Post.published.joins(:languages).where(default_filter).where('post_date < ?', post.post_date).order(post_date: :desc).first,
            Railspress::Post.published.joins(:languages).where(default_filter).where('post_date > ?', post.post_date).order(post_date: :asc).first
          ]
        else
          [
            Railspress::Post.published.where(default_filter).where('post_date < ?', post.post_date).order(post_date: :desc).first,
            Railspress::Post.published.where(default_filter).where('post_date > ?', post.post_date).order(post_date: :asc).first
          ]
        end
      else
        []
      end
    end
  end
end
