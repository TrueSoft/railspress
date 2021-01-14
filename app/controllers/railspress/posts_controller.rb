require_dependency "railspress/application_controller"

module Railspress
  class PostsController < ApplicationController
    include Railspress::TemplateHelper

    def by_year
      @year = params[:year].to_i
      if Railspress.multi_language
        @posts = Railspress::Post.published.descending.joins(:languages).where(default_filter).where('post_date >= ? and post_date < ?', DateTime.new(@year).beginning_of_year, DateTime.new(@year + 1).beginning_of_year).paginate(page: params[:page]).order(post_date: :desc)
      else
        @posts = Railspress::Post.published.descending.where(default_filter).where('post_date >= ? and post_date < ?', DateTime.new(@year).beginning_of_year, DateTime.new(@year + 1).beginning_of_year).paginate(page: params[:page]).order(post_date: :desc)
      end
      render action: :index
    end

    def by_month
      if Railspress.multi_language
        @posts = Railspress::Post.published.descending.joins(:languages).where(default_filter).where('post_date >= ? and post_date < ?', DateTime.new(params[:year].to_i, params[:month].to_i, 1), DateTime.new(params[:year].to_i, params[:month].to_i, 1) + 1.month).paginate(page: params[:page]).order(post_date: :desc)
      else
        @posts = Railspress::Post.published.descending.where(default_filter).where('post_date >= ? and post_date < ?', DateTime.new(params[:year].to_i, params[:month].to_i, 1), DateTime.new(params[:year].to_i, params[:month].to_i, 1) + 1.month).paginate(page: params[:page]).order(post_date: :desc)
      end
      render action: :index
    end

    def single
      # @wp_query = Railspress::WP_Query.new(params)
      @post = @wp_query.post # Railspress::Post.published.where(post_name: params[:name]).first!
      @post_prev, @post_next = neighbours(@post)
      if Railspress.generate_breadcrumb
        @breadcrumb = {t('railspress.home.posts.title') => main_app.all_posts_path}
        @breadcrumb[@post.post_date.year] = news_of_year_path(year: @post.post_date.year) unless @post.post_date.year == Date.current.year
        @breadcrumb[@post.post_title] = nil
      end
      templates = determine_templates
      templates.each do |tmpl|
        begin
          render action: tmpl
          return
        rescue ActionView::MissingTemplate
          next
        end
      end
      render action: :single # if no other template was found until now
    rescue ActiveRecord::RecordNotFound
      redirect_to main_app.all_posts_path, alert: t('railspress.post.show.not_found', slug: params[:name])
    end

    def archive
      if params[:taxonomy] == 'author'
        @archive = Railspress::User.where(user_nicename: params[:slug]).first!
      else
        @archive = Railspress::Term.joins(:taxonomy).where(Railspress::Taxonomy.table_name => {taxonomy: params[:taxonomy]}, slug: params[:slug]).first!
      end
      if Railspress.generate_breadcrumb
        @breadcrumb = {t('railspress.home.posts.title') => main_app.all_posts_path}
        @breadcrumb[@archive.name] = nil
      end

      flt = default_filter
      if params[:taxonomy] == 'author'
        flt[:post_author] = @archive.id
        post_class = Railspress::Post
      else
        posts_for_tag = Railspress::Relationship.where(term_taxonomy_id: @archive.taxonomy.term_taxonomy_id).pluck(:object_id)
        flt[:id] = posts_for_tag

        reg_pt = get_post_type_object(@archive.slug)
        post_class = if reg_pt.nil?
                       Railspress::Post
                     else
                       custom_post_class = Class.new(Railspress::WpPost) {
                         @@custom_post_type = ''
                         def self.find_sti_class(type_name)
                           self
                         end
                         def self.sti_name
                           @@custom_post_type
                         end
                         def self.set_custom_post_type(post_type)
                           @@custom_post_type = post_type
                         end
                       }
                       custom_post_class.set_custom_post_type params[:slug]
                       custom_post_class
                     end
      end

      if Railspress.multi_language
        @posts = post_class.published.descending.joins(:languages).where(flt).paginate(page: params[:page], per_page: helpers.get_option('posts_per_page', nil))
      else
        @posts = post_class.published.descending.where(flt).paginate(page: params[:page], per_page: helpers.get_option('posts_per_page', nil))
      end

      templates =
          case params[:taxonomy]
          when 'category' then
            get_category_template
          when 'post_tag' then
            get_tag_template
          when 'author' then
            get_author_template
          else
            get_archive_template
          end

      templates.each do |tmpl|
        begin
          render action: tmpl
          return
        rescue ActionView::MissingTemplate
          next
        end
      end
      render action: :archive # if no other template was found until now
    rescue ActiveRecord::RecordNotFound
      alert_message = case params[:taxonomy]
                      when 'category' then
                        t('railspress.category.not_found', slug: params[:slug])
                      when 'post_tag' then
                        t('railspress.tag.not_found', slug: params[:slug])
                      else
                        t('railspress.taxonomy.not_found', taxonomy: params[:taxonomy], slug: params[:slug])
                      end
      redirect_to main_app.all_posts_path, alert: alert_message
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
    end
  end
end
