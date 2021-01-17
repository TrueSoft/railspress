require_dependency "railspress/application_controller"

module Railspress
  class PostsController < ApplicationController
    include Railspress::TemplateHelper

    def singular
      # @wp_query = Railspress::WP_Query.new(params)
      @post = @wp_query.post # Railspress::Post.published.where(post_name: params[:name]).first!
      @post_prev, @post_next = neighbours(@post)
      if Railspress.generate_breadcrumb
        if @post.post_type == 'post'
          @breadcrumb = {t('railspress.home.posts.title') => railspress_engine.all_posts_path}
          @breadcrumb[@post.post_date.year] = year_archive_posts_path(year: @post.post_date.year) unless @post.post_date.year == Date.current.year
          @breadcrumb[@post.post_title] = nil
        else
          @breadcrumb = {}
        end
      end
      templates = determine_templates
      logger.debug "TS_DEBUG: There are #{templates.length} possible templates: #{templates.to_s}" if Railspress.WP_DEBUG
      templates.each do |tmpl|
        begin
          render action: tmpl
          return
        rescue ActionView::MissingTemplate
          next
        end
      end
      render action: :singular # if no other template was found until now
    rescue ActiveRecord::RecordNotFound
      redirect_to railspress_engine.all_posts_path, alert: t('railspress.post.show.not_found', slug: params[:name])
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
