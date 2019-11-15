module Railspress
  module PagesHelper

    def content(c)
      shortcode = Shortcode.new
      shortcode.configuration.self_closing_tags = [:ts_childpages, :ts_revisions]
      shortcode.configuration.helpers = [ActionView::Helpers::TagHelper, PagesHelper, Railspress::FormattingHelper,
                                         Railspress::LinkTemplateHelper, Railspress::MediaHelper, Railspress::MetaHelper,
                                         Railspress::OptionsHelper, Railspress::PostsHelper, Railspress::PostTemplateHelper,
                                         Railspress::PostThumbnailTemplateHelper, Railspress::RevisionHelper]
      shortcode.register_presenter(PagePresenter, RevisionsPresenter)
      shortcode.process(c, page: @page, main_post: @main_post)
    end

    def content_html(c)
      raw content(c)
    end

    def output_page_as_card(page, no_content = false)
      output = '<div class="col-xs-12 col-md-6 col-lg-4"><div class="card mb-4">'

      if has_post_thumbnail(page)
        output += get_the_post_thumbnail(page, 'medium', { class: 'card-img-top', alt: esc_attr(page.post_title)})
      end
      output += '<div class="card-body">'
      output += content_tag(:h5, page.post_title, class: 'card-title')

      unless no_content
        if page.post_excerpt.blank?
          excerpt = get_extended(page.post_content)[:main]
        else
          excerpt = page.post_excerpt
        end
        output += '<p class="card-text">' + (excerpt || 'NO EXCERPT') + '</p>' # TODO fix NO EXCERPT
      end

      output += '<a href="' + (get_page_uri(page)) + '" class="btn btn-primary pull-right">'
      output += t('railspress.pages.show.read_more') + '&hellip;'
      output += '</a>'

      output += '</div>'
      output += '</div></div>'

      output
    end

    def get_translated_page(orig_page, required_language)
      return nil if orig_page.nil?
      page_lang = if orig_page.languages.empty?
                    nil
                  else
                    orig_page.languages.first.term.slug
                  end
      if required_language != page_lang
        logger.info "Current page language(#{orig_page.post_name}/#{page_lang}) does not match with #{required_language}"
        translations = orig_page.relationships.select {|rel| rel.taxonomy.taxonomy == 'post_translations'}
        if translations.empty?
          logger.error "Page (#{orig_page.post_name}) does not have a translation for #{required_language}!"
        else
          translation_info = maybe_unserialize(translations.first.taxonomy.description)
          translation_id = translation_info[required_language]
          if translation_id.nil?
            logger.error "Page (#{orig_page.post_name}) does not have a translation for #{required_language}"
          else # The translated version of orig_page
            return Railspress::Page.find(translation_info[required_language])
          end
        end
      end
      orig_page
    end
  end
end
