class Railspress::FileExplorerPresenter
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TranslationHelper
  include ActionView::Context
  include Railspress::Functions
  include Railspress::OptionsHelper
  include Railspress::FormattingHelper
  include ApplicationHelper

  attr_accessor :ts_attrs
  attr_accessor :tablist
  attr_accessor :initial_directory
  attr_accessor :subdirs
  attr_accessor :files

  def self.for
    [:ts_fileexplorer]
  end

  def initialize(attributes, content, additional_attributes)
    @content = content
    @attributes = attributes
    @additional_attributes = additional_attributes

    # normalize attribute keys, lowercase
    ts_atts = @attributes.transform_keys!(&:downcase)
    # override default attributes with user attributes
    ts_atts = {sort_order: 'asc', selection: ':current', only: nil, except: nil}.merge(ts_atts)
    @ts_attrs = ts_atts
    Rails.logger.error "Directory not specified!" unless ts_atts[:directory].blank?
    r_path = (Railspress.SERVERPATH + (Railspress.UPLOADS.nil? ? 'uploads' : Railspress.UPLOADS ) + '/' + ts_atts[:directory])
    @initial_directory = Pathname.new(r_path)
    @subdirs, @files = directory_contents(@initial_directory, ts_atts[:only], ts_atts[:except])
    @subdirs.sort_by!{|sd| sd.basename.to_s}
    @subdirs.reverse! if ts_atts[:sort_order] == 'desc'
    @tablist = ''
    if !@files.empty? && !@subdirs.empty?
      link_class = ts_atts[:selection] == ':current' ? 'active' : ''
      @tablist << content_tag(:li, button_tag(" . ", class: 'nav-link ' + link_class, role: 'tab', 'data-bs-toggle': 'tab', 'data-bs-target': '#dir-current'), class: 'nav-item', role: 'presentation')
    end
    @subdirs.each do |dir|
      dir_name = dir.basename.sub_ext('')
      link_class = if ts_atts[:selection] == ':first'
                     (dir == @subdirs.first ? 'active' : '')
                   elsif ts_atts[:selection] == ':last'
                     (dir == @subdirs.last ? 'active' : '')
                   else
                     (ts_atts[:selection] == dir_name.to_s ? 'active' : '')
                   end
      @tablist << content_tag(:li, button_tag(dir_name, class: 'nav-link ' + link_class, role: 'tab', 'data-bs-toggle': 'tab', 'data-bs-target': '#dir-'.concat(dir_name.to_s.gsub(/\s/, '-'))), class: 'nav-item', role: 'presentation')
    end
  end

  def content
    selection_found = false
    panels_content = ''
    unless @files.empty?
      link_class = @ts_attrs[:selection] == ':current' ? 'active' : ''
      selection_found = true unless link_class.blank?
      link_class = 'show ' + link_class unless link_class.blank?

      panels_content << content_tag( :div, content_tag(:ul,
                                                       @files.map{|file| content_tag(:li, render_file_in_explorer(file), class: 'file-item')}.join(' ').html_safe,
                                                       class: 'list-unstyled'),  class: 'tab-pane fade ' + link_class, id: 'dir-current', role: 'tabpanel', 'aria-labelledby': 'current-dir')
    end
    @subdirs.each do |dir|
      dir_name = dir.basename.sub_ext('')
      link_class = if @ts_attrs[:selection] == ':first'
                     (dir == @subdirs.first ? 'active' : '')
                   elsif @ts_attrs[:selection] == ':last'
                     (dir == @subdirs.last ? 'active' : '')
                   else
                     (@ts_attrs[:selection] == dir_name.to_s ? 'active' : '')
                   end
      selection_found = true unless link_class.blank?
      link_class = 'show ' + link_class unless link_class.blank?
      _, files = directory_contents(dir, @ts_attrs[:only], @ts_attrs[:except])
      panels_content << content_tag(:div, content_tag(:ul, files.map{|file| content_tag(:li, render_file_in_explorer(file), class: 'file-item')}.join(' ').html_safe, class: 'list-unstyled'), class: 'tab-pane fade ' + link_class, id: 'dir-' + dir_name.to_s.gsub(/\s/, '-'), role: 'tabpanel')
    end
    unless selection_found
      panels_content << content_tag(:div, class: 'tab-pane fade show active', role: 'tabpanel') do
        content_tag(:p, t('railspress.shortcodes.fileexplorer.hint_selection'), class: 'text-muted fst-italic')
      end
    end
    content_tag(:ul, id: "file-explorer-#{@initial_directory.basename.to_s.gsub(/\s/, '-')}", class: 'nav nav-tabs', role: 'tablist') do
      @tablist.html_safe
    end +
    content_tag(:div, panels_content.html_safe, id: "file-explorer-#{@initial_directory.basename.to_s.gsub(/\s/, '-')}-content", class: 'tab-content file-explorer bg-white border border-top-0 overflow-scroll', style: 'height: 20rem')
  end

  def attributes
    @attributes.merge({}) # page: @additional_attributes[:page], main_post: @additional_attributes[:main_post]})
  end

  def directory_contents(initial_directory, only = nil, except = nil)
    subdirs, files = [], []
    Dir.glob(initial_directory.join('*')).
      select{|o| only.blank? ? true : (File.directory?(o) || Pathname.new(o).basename.to_s =~ Regexp.new(only))}.
      reject{|o| except.blank? ? false : (File.file?(o) && Pathname.new(o).basename.to_s =~ Regexp.new(except))}.
      each do |path|
      if File.directory?(path)
        subdirs << Pathname.new(path)
      else
        files << Pathname.new(path)
      end
    end
    [subdirs, files]
  end

  def render_file_in_explorer(file)
    file_type = File.extname(file.basename).strip.downcase[1..-1]
    link_to((get_option('siteurl').gsub(/[\/]+$/, '') + '/' + file.to_path[Railspress.SERVERPATH.to_s.length..-1].gsub(/^[\/]+/, '')), class: "file-link file-type-#{file_type}", title: file.basename) do
      content_tag(:span, fabi_icon(icon_for_filetype(file_type)), class: 'file-icon') +
        content_tag(:span, class: 'file-name') do
          concat file.basename.sub_ext('')
          concat content_tag(:span, file_type.nil? ? '' : '.' + file_type, class: 'file-extension')
        end +
        content_tag(:small, t('railspress.shortcodes.fileexplorer.created_at', date: File.mtime(file).strftime('%d/%m/%Y')), class: 'file-created-at text-muted fst-italic')
    end
  end

  def icon_for_filetype(ext)
    case ext
    when 'gif', 'jpg', 'jpeg', 'png' then
      'file-earmark-image'
    when 'doc', 'docx' then
      'file-earmark-word'
    when 'xls', 'xlsx' then
      'file-earmark-spreadsheet'
    when 'ppt', 'pptx' then
      'file-earmark-ppt'
    when 'pdf' then
      'file-earmark-pdf'
    when 'txt' then
      'file-earmark-text'
    when 'rar', 'zip' then
      'file-earmark-zip'
    when 'mp3' then
      'file-earmark-music'
    when 'avi', 'mp4' then
      'file-earmark-play'
    when 'java', 'php', 'rb' then
      'file-earmark-code'
    else
      'file-earmark'
    end
  end

  private
  def get_direct_children(type, *doc_dir)
    Rails.root.join('public', *([] + doc_dir)).children.select {|fn|
      case type
      when :directory then
        File.directory?(fn)
      when :file then
        File.file?(fn)
      else
        raise "Unknown type: #{type}"
      end
    }
  end
end