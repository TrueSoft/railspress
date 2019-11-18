require_dependency "railspress/application_controller"

module Railspress
  class PostsController < ApplicationController
    def index
      if Railspress.multi_language
        @posts = Railspress::Post.published.descending.joins(:languages).where(default_filter).paginate(page: params[:page], per_page: params[:per_page])
      else
        @posts = Railspress::Post.published.descending.where(default_filter).paginate(page: params[:page], per_page: params[:per_page])
      end
    end

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

    def show
      @post = Railspress::Post.published.where(post_name: params[:slug]).first!
      @post_prev, @post_next = neighbours(@post)
      @breadcrumb = {t('railspress.post.index.title') => posts_path}
      @breadcrumb[@post.post_date.year] = news_of_year_path(year: @post.post_date.year) unless @post.post_date.year == Date.current.year
      @breadcrumb[@post.post_title] = nil
    rescue ActiveRecord::RecordNotFound
      redirect_to news_path, alert: t('railspress.post.show.not_found', slug: params[:slug])
    end

    def show_id
      @post = Railspress::Post.published.where(id: params[:id]).first!
      @post_prev, @post_next = neighbours(@post)
      @breadcrumb = {t('railspress.post.index.title') => posts_path}
      @breadcrumb[@post.post_date.year] = news_of_year_path(year: @post.post_date.year) unless @post.post_date.year == Date.current.year
      @breadcrumb[@post.post_title] = nil
      render action: :show
    rescue ActiveRecord::RecordNotFound
      redirect_to news_path, alert: t('railspress.post.show.id_not_found', id: params[:id])
    end

    def tag
      @tag = Railspress::Term.joins(:taxonomy).where(Railspress::Taxonomy.table_name => {taxonomy: 'post_tag'}, slug: params[:slug]).first!
      @breadcrumb = {t('railspress.post.index.title') => posts_path}
      @breadcrumb[@tag.name] = nil
      posts_for_tag = Railspress::Relationship.where(term_taxonomy_id: @tag.taxonomy.term_taxonomy_id).pluck(:object_id)
      flt = default_filter
      flt[:id] = posts_for_tag
      if Railspress.multi_language
        @posts = Railspress::Post.published.descending.joins(:languages).where(flt).paginate(page: params[:page], per_page: params[:per_page])
      else
        @posts = Railspress::Post.published.descending.where(flt).paginate(page: params[:page], per_page: params[:per_page])
      end
      render action: :index
    rescue ActiveRecord::RecordNotFound
      redirect_to news_path, alert: t('railspress.tag.not_found', slug: params[:slug])
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
