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
end