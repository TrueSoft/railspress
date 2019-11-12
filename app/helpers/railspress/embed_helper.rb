=begin
 * oEmbed API: Top-level oEmbed functionality
 *
 * file wp-includes\embed.php
=end
module Railspress::EmbedHelper

  # Filters the string in the 'more' link displayed after a trimmed excerpt.
  #
  # Replaces '[...]' (appended to automatically generated excerpts) with an
  # ellipsis and a "Continue reading" link in the embed template.
  #
  # @param [string] more_string Default 'more' string.
  # @return [string] 'Continue reading' link prepended with an ellipsis.
  def wp_embed_excerpt_more(more_string)
    #    if ( ! is_embed() ) {
    #        return more_string;
    #    }
    text = t('railspress.embed.continue_reading_html', title: get_the_title())  # translators: %s: Name of current post
    link = "<a href=\"#{esc_url( get_permalink() )}\" class=\"wp-embed-more\" target=\"_top\">#{text}</a>"
    ' &hellip; ' + link
  end
end