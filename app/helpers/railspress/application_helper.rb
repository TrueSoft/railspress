include FontAwesome::Rails::IconHelper

module Railspress::ApplicationHelper

  def wp_url_to_relative_url(wp_url)
    if wp_url.start_with? home_url
      wp_url[home_url.length .. -1]
    else
      wp_url
    end
  end

  def display_errors_for(object, header_message = nil)
    if object.errors.any?
      content_tag(:div, class: 'card border-danger mb-4 mx-4') do
        concat(content_tag(:div, class: 'card-header bg-danger text-white') do
          concat header_message || t('activerecord.errors.template.header', model: object.class.model_name.human.downcase, count: object.errors.count)
        end)
        concat(content_tag(:div, class: 'card-body') do
          concat(content_tag(:ul, class: 'mb-0') do
            object.errors.full_messages.each do |msg|
              concat content_tag(:li, msg)
            end
          end)
        end)
      end
    end
  end

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

  def ts_token(src)
    Digest::SHA1.hexdigest("–#{Rails.application.secrets.secret_key_base}–#{src}–")
  end
end

