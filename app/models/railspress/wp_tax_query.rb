=begin
 * Taxonomy API: WP_Tax_Query class
 *
 * file wp-includes\class-wp-tax-query.php
=end
module Railspress

  # Core class used to implement taxonomy queries for the Taxonomy API.
  #
  # Used for generating SQL clauses that filter a primary query according to object
  # taxonomy terms.
  #
  # WP_Tax_Query is a helper that allows primary query classes, such as WP_Query, to filter
  # their results by object metadata, by generating `JOIN` and `WHERE` subclauses to be
  # attached to the primary SQL query string.
  class WpTaxQuery
    # Array of taxonomy queries.
    attr_accessor :queries

    # The relation between the queries. Can be one of 'AND' or 'OR'.
    attr_accessor :relation

    # Database table that where the metadata's objects are stored (eg $wpdb->users).
    attr_accessor :primary_table

    # Column in 'primary_table' that represents the ID of the object.
    attr_accessor :primary_id_column

    # Constructor.
    #
    # @param [Array] tax_query {
    #     Array of taxonomy query clauses.
    #
    #     @type string relation Optional. The MySQL keyword used to join
    #                            the clauses of the query. Accepts 'AND', or 'OR'. Default 'AND'.
    #     @type array {
    #         Optional. An array of first-order clause parameters, or another fully-formed tax query.
    #
    #         @type string           taxonomy         Taxonomy being queried. Optional when field=term_taxonomy_id.
    #         @type string|int|array terms            Term or terms to filter by.
    #         @type string           field            Field to match $terms against. Accepts 'term_id', 'slug',
    #                                                'name', or 'term_taxonomy_id'. Default: 'term_id'.
    #         @type string           operator         MySQL operator to be used with $terms in the WHERE clause.
    #                                                 Accepts 'AND', 'IN', 'NOT IN', 'EXISTS', 'NOT EXISTS'.
    #                                                 Default: 'IN'.
    #         @type bool             include_children Optional. Whether to include child terms.
    #                                                 Requires a $taxonomy. Default: true.
    #     }
    # }
    def initialize(tax_query)
      if false && !tax_query['relation'].blank? # TS_INFO: If tax_query is array, how come it has 'relation'?
        @relation = sanitize_relation tax_query['relation']
      else
        @relation = 'AND'
      end
      @queries = sanitize_query tax_query
    end

    # Ensure the 'tax_query' argument passed to the class constructor is well-formed.
    #
    # Ensures that each query-level clause has a 'relation' key, and that
    # each first-order clause contains all the necessary keys from `$defaults`.
    #
    # @param [array] queries Array of queries clauses.
    # @return [array] Sanitized array of query clauses.
    def sanitize_query(queries)
      cleaned_query = {}

      defaults = {
        taxonomy: '',
        terms: [],
        field: 'term_id',
        operator: 'IN',
        include_children: true,
      }
      # queries.each do |key, query|
      #   # TODO continue
      # end
      cleaned_query = queries

      cleaned_query
    end

    # Sanitize a 'relation' operator.
    #
    # @param [String] relation Raw relation key from the query argument.
    # @return [String] Sanitized relation ('AND' or 'OR').
    def sanitize_relation(relation)
      if 'OR' == relation.upcase
        'OR'
      else
        'AND'
      end
    end

    # Determine whether a clause is first-order.
    #
    # A "first-order" clause is one that contains any of the first-order
    # clause keys ('terms', 'taxonomy', 'include_children', 'field',
    # 'operator'). An empty clause also counts as a first-order clause,
    # for backward compatibility. Any clause that doesn't meet this is
    # determined, by process of elimination, to be a higher-order query.
    #
    # @param [Array] query Tax query arguments.
    # @return [Boolean] Whether the query clause is a first-order clause.
    def is_first_order_clause(query)
      # TODO is_array( $query ) && ( empty( $query ) || array_key_exists( 'terms', $query ) || array_key_exists( 'taxonomy', $query ) || array_key_exists( 'include_children', $query ) || array_key_exists( 'field', $query ) || array_key_exists( 'operator', $query ) );
      true
    end

    # Generates SQL clauses to be appended to a main query.
    #
    # @param [String] primary_table     Database table where the object being filtered is stored (eg wp_users).
    # @param [string] primary_id_column ID column for the filtered object in $primary_table.
    # @return array {
    #     Array containing JOIN and WHERE SQL clauses to append to the main query.
    #
    #     @type string join  SQL fragment to append to the main JOIN clause.
    #     @type string where SQL fragment to append to the main WHERE clause.
    # }
    def get_sql(primary_table, primary_id_column)
      @primary_table     = primary_table
      @primary_id_column = primary_id_column

      get_sql_clauses
    end

    # Generate SQL clauses to be appended to a main query.
    #
    # Called by the public WP_Tax_Query::get_sql(), this method
    # is abstracted out to maintain parity with the other Query classes.
    #
    # @since 4.1.0
    #
    # @return array {
    #     Array containing JOIN and WHERE SQL clauses to append to the main query.
    #
    #     @type string $join  SQL fragment to append to the main JOIN clause.
    #     @type string $where SQL fragment to append to the main WHERE clause.
    # }
    def get_sql_clauses
      # queries are passed by reference to get_sql_for_query() for recursion.
      # To keep @queries unaltered, pass a copy.
      queries = [] + @queries
      sql = get_sql_for_query( queries )

      sql['where'] = ' AND ' + sql['where'] unless sql['where'].blank?

      sql
    end

    # Generate SQL clauses for a single query array.
    #
    # If nested subqueries are found, this method recurses the tree to
    # produce the properly nested SQL.
    #
    # @param [Array] query Query to parse (passed by reference).
    # @param [Integer]   depth Optional. Number of tree levels deep we currently are.
    #                     Used to calculate indentation. Default 0.
    # @return array {
    #     Array containing JOIN and WHERE SQL clauses to append to a single query array.
    #
    #     @type string $join  SQL fragment to append to the main JOIN clause.
    #     @type string $where SQL fragment to append to the main WHERE clause.
    # }
    def get_sql_for_query( query, depth = 0 )
      sql_chunks = {'join' => [], 'where' => []}
      sql = {'join' => '', 'where' => ''}
      indent = ''
      indent += '  ' * depth

      relation = ''

      query.each do |clause|
        # currently ignoring relation
        if is_first_order_clause clause
          clause_sql = get_sql_for_clause( clause, query )
          where_count= clause_sql['where'].length
          if where_count == 0
            sql_chunks['where'] << ''
          elsif where_count == 1
            sql_chunks['where'] << clause_sql['where'][0]
          else
            sql_chunks['where'] << '( ' + clause_sql['where'].join(' AND ') + ' )'
          end
          sql_chunks['join'] = sql_chunks['join'] + clause_sql['join']
        else # This is a subquery, so we recurse.
          clause_sql = get_sql_for_query( clause, depth + 1 )

          # $sql_chunks['where'][] = $clause_sql['where'];
          # $sql_chunks['join'][]  = $clause_sql['join'];
        end
      end

      # Filter to remove empties.
      sql_chunks['join']  = sql_chunks['join'].select {|j| !j.blank? }
      sql_chunks['where'] = sql_chunks['where'].select {|w| !w.blank? }

      relation = 'AND' if relation.blank?

      # Filter duplicate JOIN clauses and combine into a single string.
      unless sql_chunks['join'].blank?
        sql['join'] = sql_chunks['join'].uniq.join(' ')
      end

      # Generate a single WHERE clause with proper brackets and indentation.
      unless sql_chunks['where'].blank?
          sql['where'] = '( ' + "\n  " + indent + sql_chunks['where'].join(' ' + "\n  " + indent + relation + ' ' + "\n  " + indent) + "\n" + indent + ')'
      end

      sql
    end

    # Generate SQL JOIN and WHERE clauses for a "first-order" query clause.
    #
    # @global wpdb $wpdb The WordPress database abstraction object.
    #
    # @param [Array] clause       Query clause (passed by reference).
    # @param [Array] parent_query Parent query array.
    # @return [Hash] {
    #     Array containing JOIN and WHERE SQL clauses to append to a first-order query.
    #
    #     @type string $join  SQL fragment to append to the main JOIN clause.
    #     @type string $where SQL fragment to append to the main WHERE clause.
    # }
    def get_sql_for_clause( clause, parent_query )
      sql = {'where' => [], 'join' => []}
      join = where = ''

      clean_query( clause )

      # if ( is_wp_error( $clause ) ) {
      #   return self::$no_results;
      # }
      terms    = clause['terms']
      operator = clause['operator'].nil? ? nil : clause['operator'].upcase

      if 'IN' == operator

      elsif 'NOT IN' == operator

      elsif 'AND' == operator

      elsif 'NOT EXISTS' == operator || 'EXISTS' == operator

      end
      # TODO continue

      sql['join'] << join
      sql['where'] << where

      sql
    end

    # Identify an existing table alias that is compatible with the current query clause.
    #
    # We avoid unnecessary table joins by allowing each clause to look for
    # an existing table alias that is compatible with the query that it
    # needs to perform.
    #
    # An existing alias is compatible if (a) it is a sibling of `$clause`
    # (ie, it's under the scope of the same relation), and (b) the combination
    # of operator and relation between the clauses allows for a shared table
    # join. In the case of WP_Tax_Query, this only applies to 'IN'
    # clauses that are connected by the relation 'OR'.
    #
    # @param [array]       clause       Query clause.
    # @param [array]       parent_query Parent query of $clause.
    # @return [string|false] Table alias if found, otherwise false.
    def find_compatible_table_alias( clause, parent_query )
      alias_ = false

      # Sanity check. Only IN queries use the JOIN syntax .
      return alias_ if parent_query['operator'].blank? || 'IN' != parent_query['operator']

      # Since we're only checking IN queries, we're only concerned with OR relations.
      return alias_ if parent_query['relation'].blank? || 'OR' != parent_query['relation']

      compatible_operators = [ 'IN' ]
      parent_query.each do |sibling|
        next if !sibling.is_a?(Array) || !is_first_order_clause(sibling)
        next if sibling['alias'].blank? || sibling['operator'].blank?
        # The sibling must both have compatible operator to share its alias.
        if compatible_operators.include? sibling['operator'].upcase
          alias_ = sibling['alias']
          break
        end
      end

      alias_
    end

    # Validates a single query.
    #
    # @param [Array] query The single query. Passed by reference.
    def clean_query(query)
      # if ( empty( $query['taxonomy'] ) ) {
      # 			if ( 'term_taxonomy_id' !== $query['field'] ) {
      # 				$query = new WP_Error( 'invalid_taxonomy', __( 'Invalid taxonomy.' ) );
      # 				return;
      # 			}
      #
      # 			// so long as there are shared terms, include_children requires that a taxonomy is set
      # 			$query['include_children'] = false;
      # 		} elseif ( ! taxonomy_exists( $query['taxonomy'] ) ) {
      # 			$query = new WP_Error( 'invalid_taxonomy', __( 'Invalid taxonomy.' ) );
      # 			return;
      # 		}
      #
      # 		$query['terms'] = array_unique( (array) $query['terms'] );
      #
      # 		if ( is_taxonomy_hierarchical( $query['taxonomy'] ) && $query['include_children'] ) {
      # 			$this->transform_query( $query, 'term_id' );
      #
      # 			if ( is_wp_error( $query ) ) {
      # 				return;
      # 			}
      #
      # 			$children = array();
      # 			foreach ( $query['terms'] as $term ) {
      # 				$children   = array_merge( $children, get_term_children( $term, $query['taxonomy'] ) );
      # 				$children[] = $term;
      # 			}
      # 			$query['terms'] = $children;
      # 		}
      transform_query( query, 'term_taxonomy_id' )
    end

    # Transforms a single query, from one field to another.
    #
    # Operates on the `$query` object by reference. In the case of error,
    # `$query` is converted to a WP_Error object.
    #
    # @global wpdb $wpdb The WordPress database abstraction object.
    #
    # @param [Array]  query           The single query. Passed by reference.
    # @param [String] resulting_field The resulting field. Accepts 'slug', 'name', 'term_taxonomy_id',
    #                                 or 'term_id'. Default 'term_id'.
    def transform_query(query, resulting_field)
      return if query['terms'].blank?
      return if query['field'] == resulting_field

      resulting_field = sanitize_key( resulting_field )
      # Empty 'terms' always results in a null transformation.
      terms = query['terms'].select {|j| !j.blank? }
      if terms.blank?
        query[terms] = []
        query[field = resulting_field]
        return
      end
      args = {
        'get'                    => 'all',
        'number'                 => 0,
        'taxonomy'               => query['taxonomy'],
        'update_term_meta_cache' => false,
        'orderby'                => 'none',
      }
      # Term query parameter name depends on the 'field' being searched on.
      case query['field']
      when 'slug'
        args['slug'] = terms
      when 'name'
        args['name'] = terms
      when 'term_taxonomy_id'
        args['term_taxonomy_id'] = terms
      else
        args['include'] = wp_parse_id_list( terms )
      end

      # $term_query = new WP_Term_Query();
      # $term_list  = $term_query->query( $args );
      #
      # if ( is_wp_error( $term_list ) ) {
      #   $query = $term_list;
      # return;
      # }
      #
      # if ( 'AND' == $query['operator'] && count( $term_list ) < count( $query['terms'] ) ) {
      #   $query = new WP_Error( 'inexistent_terms', __( 'Inexistent terms.' ) );
      # return;
      # }
      #
      # query['terms'] = wp_list_pluck( term_list, resulting_field )
      query['field'] = resulting_field

    end

  end
end
