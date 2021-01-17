class Railspress::HomeController < Railspress::ApplicationController
  include Railspress::TemplateHelper

  def index
    @post = @wp_query.get_queried_object
    if @post.nil?
      if Railspress.multi_language
        @posts = Railspress::Post.published.descending.joins(:languages).where(default_filter).paginate(page: params[:page], per_page: helpers.get_option('posts_per_page', nil))
      else
        @posts = Railspress::Post.published.descending.where(default_filter).paginate(page: params[:page], per_page: helpers.get_option('posts_per_page', nil))
      end
    else
      if @post.post_status == 'private'
        event_check_si = Railspress.main_app_hook.on_check_signed_in
        if !event_check_si.nil? && !event_check_si.on(:signed_in?, @post, session)
          redirect_to main_app.root_path, alert: t('railspress.pages.show.no_public', slug: params[:pagename])
          return
        end
      end
      orig_page_id = @post.id
      if Railspress.multi_language
        # ---- Get the translated version if it is the case
        @post = helpers.get_translated_page @post, params[:language] || I18n.default_locale.to_s
        if orig_page_id != @post.id
          parsed_locale = params[:language] || I18n.default_locale.to_s
          logger.info "Redirecting to translated version (#{@post.post_name}/#{parsed_locale})"
          redirect_to show_page_path(helpers.get_page_uri(@post), language: parsed_locale == I18n.default_locale.to_s ? nil : params[:language])  # TODO de verificat
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
        unless event.on(:show_page, @post, session)
          redirect_to main_app.root_path, alert: (event.temp_message || t('railspress.pages.show.not_allowed', slug: params[:pagename]))
          return
        end
      end
      if Railspress.multi_language
        @latest_posts = Railspress::Post.published.descending.joins(:languages).where(default_filter).first(2)
      else
        @latest_posts = Railspress::Post.published.descending.where(default_filter).first(2)
      end
      @post_class = @post.metas.select {|meta| meta.meta_key == 'post-class'}.map {|meta| meta.meta_value}.first
    end
    templates = determine_templates
    logger.debug "TS_DEBUG: There are #{templates.length} possible templates: #{templates.to_s}" if Railspress.WP_DEBUG
    templates.each do |tmpl|
      begin
        # tmpl = tmpl.gsub(/\.php$/, '')
        render action: tmpl
        return
      rescue ActionView::MissingTemplate
        next
      end
    end
    # render action: :index # if no other template was found until now
  end

  def posts
    if Railspress.multi_language
      @posts = Railspress::Post.published.descending.joins(:languages).where(default_filter).paginate(page: params[:page], per_page: helpers.get_option('posts_per_page', nil))
    else
      @posts = Railspress::Post.published.descending.where(default_filter).paginate(page: params[:page], per_page: helpers.get_option('posts_per_page', nil))
    end
    templates = determine_templates
    templates.each do |tmpl|
      begin
        # tmpl = tmpl.gsub(/\.php$/, '')
        render action: tmpl
        return
      rescue ActionView::MissingTemplate
        next
      end
    end
    render action: :home # if no other template was found until now
  end

  def testing_page
  end

end
