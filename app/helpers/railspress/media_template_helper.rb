=begin
 * WordPress media templates.
 *
 * file wp - includes\media-template.php
=end
module Railspress::MediaTemplateHelper

  # Output the markup for a video tag to be used in an Underscore template when data.model is passed.
  def wp_underscore_video_template
    video_types = wp_get_video_extensions
  end
end