class Railspress::ArchiveController < Railspress::ApplicationController
  include Railspress::TemplateHelper

  def author
    @archive = Railspress::User.where(user_nicename: params[:slug]).first!
    prepare_vars
  end

  def taxonomy
    if params[:taxonomy] == 'author'
      @archive = Railspress::User.where(user_nicename: params[:slug]).first!
    else
      @archive = Railspress::Term.joins(:taxonomy).where(Railspress::Taxonomy.table_name => {taxonomy: params[:taxonomy]}, slug: params[:slug]).first!
    end
    prepare_vars
  end

  def year_archive
    @year = params[:year].to_i
    if Railspress.multi_language
      @posts = Railspress::Post.published.descending.joins(:languages).where(default_filter).where('post_date >= ? and post_date < ?', DateTime.new(@year).beginning_of_year, DateTime.new(@year + 1).beginning_of_year).paginate(page: params[:page]).order(post_date: :desc)
    else
      @posts = Railspress::Post.published.descending.where(default_filter).where('post_date >= ? and post_date < ?', DateTime.new(@year).beginning_of_year, DateTime.new(@year + 1).beginning_of_year).paginate(page: params[:page]).order(post_date: :desc)
    end
    templates = get_date_template
    templates.each do |tmpl|
      begin
        render action: tmpl
        return
      rescue ActionView::MissingTemplate
        next
      end
    end
    render action: :date
  end

  def month_archive
    @year_month = DateTime.new(params[:year].to_i, params[:monthnum].to_i, 1)
    if Railspress.multi_language
      @posts = Railspress::Post.published.descending.joins(:languages).where(default_filter).where('post_date >= ? and post_date < ?', DateTime.new(params[:year].to_i, params[:monthnum].to_i, 1), DateTime.new(params[:year].to_i, params[:monthnum].to_i, 1) + 1.month).paginate(page: params[:page]).order(post_date: :desc)
    else
      @posts = Railspress::Post.published.descending.where(default_filter).where('post_date >= ? and post_date < ?', DateTime.new(params[:year].to_i, params[:monthnum].to_i, 1), DateTime.new(params[:year].to_i, params[:monthnum].to_i, 1) + 1.month).paginate(page: params[:page]).order(post_date: :desc)
    end
    templates = get_date_template
    templates.each do |tmpl|
      begin
        render action: tmpl
        return
      rescue ActionView::MissingTemplate
        next
      end
    end
    render action: :date
  end

  private

  def prepare_vars
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
end
