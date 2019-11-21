module Railspress::ApplicationHelper

  def wp_url_to_relative_url(wp_url)
    if wp_url.start_with? home_url
      wp_url[home_url.length .. -1]
    else
      wp_url
    end
  end

  def svg_icon(icon)
    case icon
    when :edit
      '<svg width="16" height="16" viewBox="0 0 24 24" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
        <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"></path>
        <path d="M0 0h24v24H0z" fill="none"></path>
      </svg>'.html_safe
    when :remove
      '<svg width="16" height="16" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <path d="M24 20.188l-8.315-8.209 8.2-8.282-3.697-3.697-8.212 8.318-8.31-8.203-3.666 3.666 8.321 8.24-8.206 8.313 3.666 3.666 8.237-8.318 8.285 8.203z"/>
      </svg>'.html_safe
    else
      nil
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

