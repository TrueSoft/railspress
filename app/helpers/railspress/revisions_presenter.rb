class Railspress::RevisionsPresenter
  include ActionView::Context
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include Railspress::ApplicationHelper
  include Railspress::RevisionHelper
  include Railspress::PostsHelper

  attr_accessor :heading
  attr_accessor :title_format
  attr_accessor :revisions
  attr_accessor :collapse
  attr_accessor :class_name
  attr_accessor :heading_class_name

  def self.for
    [:ts_revisions]
  end

  def initialize(attributes, content, additional_attributes)
    @content = content
    @attributes = attributes
    @additional_attributes = additional_attributes
    main_post_id = @additional_attributes[:main_post].nil? ? @additional_attributes[:page].id : @additional_attributes[:main_post].id
    main_post_date = @additional_attributes[:main_post].nil? ? @additional_attributes[:page].post_modified : @additional_attributes[:main_post].post_modified

    # normalize attribute keys, lowercase
    ts_atts = @attributes.transform_keys!(&:downcase)
    # override default attributes with user attributes
    ts_atts = {sort_column: 'post_date', sort_order: 'desc', title_format: "%B %Y", group_by_format: nil, heading: "Arhiva", class: nil, heading_class: nil, collapse: false}.merge(ts_atts)

    rev_args = {orderby: ts_atts[:sort_column], order: ts_atts[:sort_order].to_sym}

    @revisions = wp_get_post_revisions(main_post_id, rev_args).values
    @revisions = filter_revisions_by_group_format(@revisions, ts_atts[:group_by_format].to_s, main_post_date)
    @heading = ts_atts[:heading]
    @title_format = ts_atts[:title_format]
    @collapse = ts_atts[:collapse]
    @class_name = ts_atts[:class]
    @heading_class_name = ts_atts[:heading_class]
  end

  def content
    return '' if @revisions.empty?
    card_class = ('card post-revisions ' + (@class_name || '')).strip
    card_heading_class = ('card-header p-2 ' + (@heading_class_name || '')).strip
    if @collapse
      card_heading_class += ' collapsed btn text-left font-weight-bold'
      content_tag :div, id:'ts-post-revisions', class: card_class do
        link_to(@heading, '#ts-post-revisions-collapse', id: 'ts-post-revisions-heading', class: card_heading_class, 'data-toggle': 'collapse', role: 'button', 'aria-expanded': false, 'aria-controls': 'ts-post-revisions-collapse') +
            content_tag(:ul, @revisions.each.map {|revision| revision_link_item(revision, @title_format)}.join.html_safe, class: 'card-body post-revisions ml-2 mb-0 py-2 collapse', id: 'ts-post-revisions-collapse', 'data-parent': '#ts-post-revisions', 'aria-labelledby': 'ts-post-revisions-heading')
      end
    else
      content_tag :div, id:'ts-post-revisions', class: card_class do
        content_tag(:h5, @heading, class: card_heading_class) +
            content_tag(:ul, @revisions.each.map {|revision| revision_link_item(revision, @title_format)}.join.html_safe, class: 'card-body post-revisions ml-2 mb-0 py-2')
      end
    end
  end

  def attributes
    @attributes.merge({page: @additional_attributes[:page], main_post: @additional_attributes[:main_post]})
  end

  private

  def filter_revisions_by_group_format(revisions, group_by_format, main_post_date = nil)
    return revisions if group_by_format.blank?
    result = []
    gb_hash = []
    gb_main = main_post_date.nil? ? nil : main_post_date.strftime(group_by_format)
    revisions.each do |revision|
      # get_permalink(revision)
      gb = revision.post_date.strftime(group_by_format)
      next if gb_hash.include? gb
      next if gb == gb_main # ignore the posts which have the same path like the main one
      gb_hash << gb
      result << revision
    end
    result
  end

  def revision_link_item(revision, title_format)
    link_prefix = (revision.id == @additional_attributes[:page].id) ? nil : '/'
    title_str = I18n.l(revision.post_date, format: title_format)
    html_options = {class: (link_prefix.nil? ? 'active font-weight-bold' : nil)}
    # get_permalink(revision)
    title = link_to_unless link_prefix.nil?, title_str, '?' + {rev: revision.id, token: ts_token(revision.id)}.to_query
    content_tag(:li, title, html_options)
  end
end