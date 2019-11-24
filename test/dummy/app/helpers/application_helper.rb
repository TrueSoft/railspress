module ApplicationHelper

  def display_breadcrumb(breadcrumb)
    unless breadcrumb.nil?
      unless breadcrumb.blank?
        breadcrumb[breadcrumb.keys.last] = nil
      end
      content_tag :nav, 'aria-label': 'breadcrumb' do
        content_tag :ol, class: 'breadcrumb' do
          breadcrumb.each do |text, path|
            if path.nil?
              concat content_tag :li, text, class: 'breadcrumb-item active'
            elsif path.is_a? Hash
              concat content_tag :li, link_to(text, path[:url]), class: 'breadcrumb-item', title: path[:title]
            else
              concat content_tag :li, link_to(text, path), class: 'breadcrumb-item'
            end
          end
        end
      end
    end
  end
end
