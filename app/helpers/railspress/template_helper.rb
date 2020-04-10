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
	# @since 1.5.0
	# @since 4.8.0 The `$type` and `$templates` parameters were added.
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

# TODO get_post_type_archive_template

 # Retrieve path of author template in current or parent template.
 #
 # The hierarchy for this template looks like:
 #
 # 1. author-{nicename}.php
 # 2. author-{id}.php
 # 3. author.php
 #
 # An example of this is:
 #
 # 1. author-john.php
 # 2. author-1.php
 # 3. author.php
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'author'.
 #
 # @since 1.5.0
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
 # 1. category-{slug}.php
 # 2. category-{id}.php
 # 3. category.php
 #
 # An example of this is:
 #
 # 1. category-news.php
 # 2. category-2.php
 # 3. category.php
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'category'.
 #
 # @since 1.5.0
 # @since 4.7.0 The decoded form of `category-{slug}.php` was added to the top of the
 #              template hierarchy when the category slug contains multibyte characters.
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
 # 1. tag-{slug}.php
 # 2. tag-{id}.php
 # 3. tag.php
 #
 # An example of this is:
 #
 # 1. tag-wordpress.php
 # 2. tag-3.php
 # 3. tag.php
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'tag'.
 #
 # @since 2.3.0
 # @since 4.7.0 The decoded form of `tag-{slug}.php` was added to the top of the
 #              template hierarchy when the tag slug contains multibyte characters.
 #
 # @see get_query_template()
 #
 # @return string Full path to tag template file.
def get_tag_template() 
	tag = get_queried_object()

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
 # 1. taxonomy-{taxonomy_slug}-{term_slug}.php
 # 2. taxonomy-{taxonomy_slug}.php
 # 3. taxonomy.php
 #
 # An example of this is:
 #
 # 1. taxonomy-location-texas.php
 # 2. taxonomy-location.php
 # 3. taxonomy.php
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'taxonomy'.
 #
 # @see get_query_template()
 #
 # @return string Full path to custom taxonomy term template file.
def get_taxonomy_template() 
	term = get_queried_object()

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

	return get_query_template( 'home', templates )
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

# TODO get_page_template

 # Retrieve path of search template in current or parent template.
 #
 # The template hierarchy and template path are filterable via the {@see '$type_template_hierarchy'}
 # and {@see '$type_template'} dynamic hooks, where `$type` is 'search'.
 #
 # @see get_query_template()
 #
 # @return string Full path to search template file.
def get_search_template()
	get_query_template( 'search' )
end
 
# TODO get_single_template get_embed_template get_singular_template get_attachment_template locate_template load_template

end