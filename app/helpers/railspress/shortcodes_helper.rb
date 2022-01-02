=begin
 * WordPress API for creating bbcode-like tags or what WordPress calls
 * "shortcodes". The tag and attribute parsing or regular expression code is
 * based on the Textpattern tag parser.
 *
 * A few examples are below:
 *
 * [shortcode /]
 * [shortcode foo="bar" baz="bing" /]
 * [shortcode foo="bar"]content[/shortcode]
 *
 * file wp-includes\shortcodes.php
=end
module Railspress::ShortcodesHelper

=begin
 * Container for storing shortcode tags and their hook to call for the shortcode
 *
 * @name $shortcode_tags
 * @var array
 * @global array $shortcode_tags
=end
  #  $shortcode_tags = array();

  # Remove all shortcode tags from the given content.
  # @param [String] content Content to remove shortcode tags.
  # @return Content without shortcode tags
  def strip_shortcodes(content)
    return content unless content.include? '['
    # global $shortcode_tags;
    # if ( empty( $shortcode_tags ) || ! is_array( $shortcode_tags ) ) {
    #     return $content;
    # }
    # TODO continue strip_shortcodes()
    content
  end

  # Strips a shortcode tag based on RegEx matches against post content.
  # @param m RegEx matches against post content.
  # @return string|false The content stripped of the tag, otherwise false.
  def strip_shortcode_tag(m)
    # allow [[foo]] syntax for escaping a tag
    if m[1] == '[' && m[6] == ']'
      return m[0].slice(1..-2)
    end
    m[1] + m[6]
  end

  def content(c)
    shortcode = Shortcode.new
    shortcode.configuration.template_path = "app/views/railspress/shortcode_templates"
    shortcode.configuration.self_closing_tags = [:ts_childpages, :ts_revisions, :ts_customposts]
    shortcode.configuration.helpers = [ActionView::Helpers::TagHelper, Railspress::FormattingHelper,
                                       Railspress::LinkTemplateHelper, Railspress::MediaHelper, Railspress::MetaHelper,
                                       Railspress::OptionsHelper, Railspress::PostsHelper, Railspress::PostTemplateHelper,
                                       Railspress::PostThumbnailTemplateHelper, Railspress::RevisionHelper, Railspress::ShortcodesHelper]
    shortcode.register_presenter(Railspress::PagePresenter, Railspress::RevisionsPresenter, Railspress::CustomPostPresenter)
    processed_c = shortcode.process(c, page: @post, main_post: @main_post)
    process_video_blocks processed_c
  end

  def content_html(c)
    raw content(c)
  end

  def process_video_blocks(c)
    original_content = c
    begin
      regex_start = /(<!-- wp:core-embed\/(vimeo|youtube)\s*(\{.*\})\s*-->)/
      regex_end = /(<!-- \/wp:core-embed\/(vimeo|youtube)\s*-->)/
      starts_of_blocks = c.scan(regex_start)
      ends_of_blocks = c.scan(regex_end)
      replacements = []
      if !starts_of_blocks.blank? && starts_of_blocks.length == ends_of_blocks.length
        cursor = 0
        starts_of_blocks.each_with_index do |start_of_block, si|
          v_params = JSON.parse(start_of_block[2]).symbolize_keys
          s_index = c.index(start_of_block[0], cursor)
          cursor = s_index + start_of_block[0].length
          e_index = c.index(ends_of_blocks[si][0], cursor)
          cursor = e_index + ends_of_blocks[si][0].length
          block_content_indices = [s_index + start_of_block[0].length, e_index - 1]
          unless v_params[:url].blank?
            to_replace_start = c.index(v_params[:url], block_content_indices.first)
            raise "Video url #{v_params[:url]} not found in block." if to_replace_start > block_content_indices.last
            replacement = case v_params[:providerNameSlug]
                          when 'youtube'
                          then
                            match_yt = v_params[:url].scan(/^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*/)
                            if !match_yt.blank? && match_yt.first[6].length == 11
                              content_tag(:iframe, '', width: 640, height:360,
                                          src: 'https://www.youtube.com/embed/' + match_yt.first[6],
                                          frameborder: 0, allow: 'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture', allowfullscreen: true)
                            else
                              nil
                            end
                          when 'vimeo' then
                            match_v = v_params[:url].scan(/^https?:\/\/(www\.)?vimeo.com\/(?:channels\/(?:\w+\/)?|groups\/([^\/]*)\/videos\/|)(\d+)(?:|\/\?)/)
                            if !match_v.blank? && !match_v.first[2].blank?
                              content_tag(:iframe, '', width: 640, height:360,
                                          src: 'https://player.vimeo.com/video/' + match_v.first[2],
                                          frameborder: 0, allow: 'autoplay; fullscreen', allowfullscreen: true)
                            else
                              nil
                            end
                          else
                            nil
                          end
            replacements << [[to_replace_start, v_params[:url].length], replacement] unless replacement.nil?
          end
        end
      end
      replacements.reverse.each do |repl|
        c[repl[0][0], repl[0][1]] = repl[1]
      end
      c
    rescue => err
      logger.error "Error parsing video tag: #{err.to_s}"
      original_content
    end
  end

  def output_page_as_card(page, no_content = false)
    output = '<div class="col-xs-12 col-md-6 col-lg-4"><div class="card mb-4">'

    if has_post_thumbnail(page)
      output += get_the_post_thumbnail(page, 'medium', { class: 'card-img-top', alt: esc_attr(page.post_title)})
    end
    output += content_tag(:h5, page.post_title, class: 'card-header card-title')
    output += '<div class="card-body">'

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

end