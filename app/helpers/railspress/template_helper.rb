=begin
 * Template loading functions.
 *
 * file wp-includes\template.php
=end
module Railspress::TemplateHelper

 # Retrieve path to a template
 #
 # Used to quickly retrieve the path of a template without including the file
 # extension. It will also check the parent theme, if the file exists, with
 # the use of locate_template(). Allows for more generic template location
 # without the use of the other get_*_template() functions.
 #
 # @param [string] type      Filename without extension.
 # @param [array]  templates An optional list of template candidates
 # @return [string] Full path to template file.
def get_query_template( type, templates = [] ) 
	type = type.gsub(/[^a-z0-9-]+/, '')

	templates = [type]  if templates.blank?

	# Filters the list of template filenames that are searched for when retrieving a template to use.
	#
	# The last element in the array should always be the fallback template for this query type.
	#
	# Possible values for `$type` include: 'index', '404', 'archive', 'author', 'category', 'tag', 'taxonomy', 'date',
	# 'embed', 'home', 'frontpage', 'privacypolicy', 'page', 'paged', 'search', 'single', 'singular', and 'attachment'.
	#
	# @param array $templates A list of template candidates, in descending order of priority.
	templates = apply_filters( "#{type}_template_hierarchy", templates )

	if true # TS_INFO: It returns here all the templates, because the check will be done in the controller
		return templates
	end

	template = locate_template( templates )

	# Filters the path of the queried template by type.
	#
	# The dynamic portion of the hook name, `$type`, refers to the filename -- minus the file
	# extension and any non-alphanumeric characters delimiting words -- of the file to load.
	# This hook also applies to various types of files loaded as part of the Template Hierarchy.
	#
	# Possible values for `$type` include: 'index', '404', 'archive', 'author', 'category', 'tag', 'taxonomy', 'date',
	# 'embed', 'home', 'frontpage', 'privacypolicy', 'page', 'paged', 'search', 'single', 'singular', and 'attachment'.
	#
	# @param string $template  Path to the template. See locate_template().
	# @param string $type      Sanitized filename without extension.
	# @param array  $templates A list of template candidates, in descending order of priority.
	apply_filters( "#{type}_template", template, type, templates )
end

 # Retrieve path of index template in current or parent template.
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'index'.
 #
 # @see get_query_template()
 #
 # @return string Full path to index template file.
def get_index_template() 
	get_query_template( 'index' )
end

 # Retrieve path of 404 template in current or parent template.
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is '404'.
 #
 # @see get_query_template()
 #
 # @return string Full path to 404 template file.
def get_404_template()
	get_query_template( '404' )
end

 # Retrieve path of archive template in current or parent template.
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'archive'.
 #
 # @see get_query_template()
 #
 # @return string Full path to archive template file.
def get_archive_template() 
	post_types = [] # TODO array_filter( (array) get_query_var( 'post_type' ) )

	templates = []

	if post_types.length == 1
		post_type = post_types.first
		templates << "archive-#{post_type}"
	end
	templates << 'archive'

	get_query_template( 'archive', templates )
end

 # Retrieve path of post type archive template in current or parent template.
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'archive'.
 #
 # @return string Full path to archive template file.
	def get_post_type_archive_template()
		post_type = @wp_query.get( 'post_type' )

		# ??? post_type = reset( post_type ) if post_type.is_a?(Array)

		obj = get_post_type_object( post_type )

		return '' if !(obj.is_a?(Railspress::WpPostType)) || !obj.has_archive

		get_archive_template
	end

 # Retrieve path of author template in current or parent template.
 #
 # The hierarchy for this template looks like:
 #
 # 1. author-{nicename}
 # 2. author-{id}
 # 3. author
 #
 # An example of this is:
 #
 # 1. author-john
 # 2. author-1
 # 3. author
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'author'.
 #
 # @see get_query_template()
 #
 # @return string Full path to author template file.
def get_author_template()
	@wp_query = Railspress::WP_Query.new if @wp_query.nil?
	author = @wp_query.get_queried_object

	templates = []

	if author.is_a?(Railspress::User)
		templates << "author-#{author.user_nicename}"
		templates << "author-#{author.id}"
	end
	templates << 'author'

	get_query_template( 'author', templates )
end

 # Retrieve path of category template in current or parent template.
 #
 # The hierarchy for this template looks like:
 #
 # 1. category-{slug}
 # 2. category-{id}
 # 3. category
 #
 # An example of this is:
 #
 # 1. category-news
 # 2. category-2
 # 3. category
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'category'.
 #
 # @see get_query_template()
 #
 # @return string Full path to category template file.
def get_category_template()
	@wp_query = Railspress::WP_Query.new if @wp_query.nil?
	category = @wp_query.get_queried_object

	templates = []

	unless category.slug.blank?  
		slug_decoded = CGI::unescape( category.slug )
		if slug_decoded != category.slug 
			templates << "category-#{slug_decoded}"
		end

		templates << "category-#{category.slug}"
		templates << "category-#{category.term_id}"
	end
	templates << 'category'

	get_query_template( 'category', templates )
end

 # Retrieve path of tag template in current or parent template.
 #
 # The hierarchy for this template looks like:
 #
 # 1. tag-{slug}
 # 2. tag-{id}
 # 3. tag
 #
 # An example of this is:
 #
 # 1. tag-wordpress
 # 2. tag-3
 # 3. tag
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'tag'.
 #
 # @see get_query_template()
 #
 # @return string Full path to tag template file.
def get_tag_template() 
	tag = @wp_query.get_queried_object()

	templates = []

	unless tag.slug.blank?

		slug_decoded = CGI::unescape( tag.slug )
		if ( slug_decoded != tag.slug )
			templates << "tag-#{slug_decoded}"
		end

		templates << "tag-#{tag.slug}"
		templates << "tag-#{tag.term_id}"
	end
	templates << 'tag'

	get_query_template( 'tag', templates )
end

 # Retrieve path of custom taxonomy term template in current or parent template.
 #
 # The hierarchy for this template looks like:
 #
 # 1. taxonomy-{taxonomy_slug}-{term_slug}
 # 2. taxonomy-{taxonomy_slug}
 # 3. taxonomy
 #
 # An example of this is:
 #
 # 1. taxonomy-location-texas
 # 2. taxonomy-location
 # 3. taxonomy
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'taxonomy'.
 #
 # @see get_query_template()
 #
 # @return string Full path to custom taxonomy term template file.
def get_taxonomy_template() 
	term = @wp_query.get_queried_object()

	templates = []

	unless term.slug.blank? 
		taxonomy = term.taxonomy

		slug_decoded = CGI::unescape( term.slug )
		if slug_decoded != term.slug 
			templates << "taxonomy-#{taxonomy}-#{slug_decoded}"
		end

		templates << "taxonomy-#{taxonomy}-#{term.slug}"
		templates << "taxonomy-#{taxonomy}"
	end
	templates << 'taxonomy'

	get_query_template( 'taxonomy', templates )
end

 # Retrieve path of date template in current or parent template.
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'date'.
 #
 # @see get_query_template()
 #
 # @return [string] Full path to date template file.
def get_date_template() 
	get_query_template( 'date' )
end

 # Retrieve path of home template in current or parent template.
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'home'.
 #
 # @see get_query_template()
 #
 # @return [string] Full path to home template file.
def get_home_template() 
	templates = ['home', 'index']

	get_query_template( 'home', templates )
end

# Retrieve path of front page template in current or parent template.
#
# The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
# and {@see '$type_template'} dynamic hooks, where `$type` is 'frontpage'.
#
# @see get_query_template()
#
# @return [string] Full path to front page template file.
def get_front_page_template() 
	templates =  ['front-page']

	get_query_template( 'frontpage', templates )
end

 # Retrieve path of Privacy Policy page template in current or parent template.
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'privacypolicy'.
 #
 # @see get_query_template()
 #
 # @return string Full path to privacy policy template file.
def get_privacy_policy_template() 
	templates = ['privacy-policy']

	get_query_template( 'privacypolicy', templates )
end

   # Retrieve path of page template in current or parent template.
   #
   # The hierarchy for this template looks like:
   #
   # 1. {Page Template}
   # 2. page-{page_name}
   # 3. page-{id}
   # 4. page
   #
   # An example of this is:
   #
   # 1. page-templates/full-width
   # 2. page-about
   # 3. page-4
   # 4. page
   #
   # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
   # and {@see '$type_template'} dynamic hooks, where `$type` is 'page'.
   #
   # @see get_query_template()
   #
   # @return [string] Full path to page template file.
  def get_page_template
    id       = @wp_query.get_queried_object_id()
		template = get_page_template_slug(id)
    pagename = @wp_query.get('pagename' )  # get_query_var( 'pagename' )

    if pagename.blank? && id
      # If a static page is set as the front page, $pagename will not be set. Retrieve it from the queried object
      post = @wp_query.get_queried_object()
      pagename = post.post_name if post
    end

    templates = []
    templates << template if !template.blank? && 0 == validate_file( template )

    unless pagename.blank?
      pagename_decoded =  CGI::unescape( pagename )
      templates << "page-#{pagename_decoded}" unless pagename_decoded == pagename
      templates << "page-#{pagename}"
    end

    templates << "page-#{id}" unless id.blank?
    templates << 'page'

    get_query_template( 'page', templates )
  end

 # Retrieve path of search template in current or parent template.
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'search'.
 #
 # @see get_query_template()
 #
 # @return [string] Full path to search template file.
def get_search_template()
	get_query_template( 'search' )
end

 # Retrieve path of single template in current or parent template. Applies to single Posts,
 # single Attachments, and single custom post types.
 #
 # The hierarchy for this template looks like:
 #
 # 1. {Post Type Template}
 # 2. single-{post_type}-{post_name}
 # 3. single-{post_type}
 # 4. single
 #
 # An example of this is:
 #
 # 1. templates/full-width
 # 2. single-post-hello-world
 # 3. single-post
 # 4. single
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'single'.
 #
 # @see get_query_template()
 #
 # @return [string] Full path to single template file.
  def get_single_template
    object = @wp_query.get_queried_object()

    templates = []
	unless object.post_type.blank?
		template = get_page_template_slug( object )
			
		templates << template if !template.blank? && 0 == validate_file( template )
		
		name_decoded = CGI::unescape( object.post_name )
		
		templates << "single-#{object.post_type}-#{name_decoded}" unless name_decoded == object.post_name 

		templates << "single-#{object.post_type}-#{object.post_name}"
		templates << "single-#{object.post_type}"
	end

    templates << 'single'

    get_query_template( 'single', templates )
  end

# TODO get_embed_template get_singular_template get_attachment_template locate_template load_template

end