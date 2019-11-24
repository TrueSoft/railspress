=begin
 * The plugin API is located in this file, which allows for creating actions
 * and filters and hooking functions, and methods. The functions or methods will
 * then be run when the action or filter is called.
 *
 * The API callback examples reference functions, but can be methods of classes.
 * To hook methods, you'll need to pass an array one of two ways.
 *
 * Any of the syntaxes explained in the PHP documentation for the
 * {@link https://secure.php.net/manual/en/language.pseudo-types.php#language.types.callback 'callback'}
 * type are valid.
 *
 * Also see the {@link https://codex.wordpress.org/Plugin_API Plugin API} for
 * more information and examples on how to use a lot of these functions.
 *
 * file wp-includes\plugin.php
=end
module Railspress::Plugin
  # Hook a function or method to a specific filter action.
  #
  # WordPress offers filter hooks to allow plugins to modify
  # various types of internal data at runtime.
  #
  # A plugin can modify data by binding a callback to a filter hook. When the filter
  # is later applied, each bound callback is run in order of priority, and given
  # the opportunity to modify a value by returning a new value.
  #
  # The following example shows how a callback function is bound to a filter hook.
  #
  # Note that `$example` is passed to the callback, (maybe) modified, then returned:
  #
  #     function example_callback( $example ) {
  #         // Maybe modify $example in some way.
  #         return $example;
  #     }
  #     add_filter( 'example_filter', 'example_callback' );
  #
  # Bound callbacks can accept from none to the total number of arguments passed as parameters
  # in the corresponding apply_filters() call.
  #
  # In other words, if an apply_filters() call passes four total arguments, callbacks bound to
  # it can accept none (the same as 1) of the arguments or up to four. The important part is that
  # the `$accepted_args` value must reflect the number of arguments the bound callback *actually*
  # opted to accept. If no arguments were accepted by the callback that is considered to be the
  # same as accepting 1 argument. For example:
  #
  #     // Filter call.
  #     $value = apply_filters( 'hook', $value, $arg2, $arg3 );
  #
  #     // Accepting zero/one arguments.
  #     function example_callback() {
  #         ...
  #         return 'some value';
  #     }
  #     add_filter( 'hook', 'example_callback' ); // Where $priority is default 10, $accepted_args is default 1.
  #
  #     // Accepting two arguments (three possible).
  #     function example_callback( $value, $arg2 ) {
  #         ...
  #         return $maybe_modified_value;
  #     }
  #     add_filter( 'hook', 'example_callback', 10, 2 ); // Where $priority is 10, $accepted_args is 2.
  #
  # *Note:* The function will return true whether or not the callback is valid.
  # It is up to you to take care. This is done for optimization purposes, so
  # everything is as quick as possible.
  #
  # @global array $wp_filter      A multidimensional array of all hooks and the callbacks hooked to them.
  #
  # @param [string]   tag             The name of the filter to hook the $function_to_add callback to.
  # @param [callable] function_to_add The callback to be run when the filter is applied.
  # @param [int]      priority        Optional. Used to specify the order in which the functions
  #                                   associated with a particular action are executed. Default 10.
  #                                   Lower numbers correspond with earlier execution,
  #                                   and functions with the same priority are executed
  #                                   in the order in which they were added to the action.
  # @param [int]      accepted_args   Optional. The number of arguments the function accepts. Default 1.
  # @return true
  def add_filter( tag, function_to_add, priority = 10, accepted_args = 1 )
    #global $wp_filter;

    Railspress.GLOBAL.wp_filter[tag] = Railspress::WPHook.new if Railspress.GLOBAL.wp_filter[ tag ].blank?

    Railspress.GLOBAL.wp_filter[tag].add_filter( tag, function_to_add, priority, accepted_args )
    true
  end

  # Check if any filter has been registered for a hook.
  #
  # @global array $wp_filter Stores all of the filters.
  #
  # @param [string]        tag               The name of the filter hook.
  # @param [callable|bool] function_to_check Optional. The callback to check for. Default false.
  # @return [false|int] If function_to_check is omitted, returns boolean for whether the hook has
  #                     anything registered. When checking a specific function, the priority of that
  #                     hook is returned, or false if the function is not attached. When using the
  #                     function_to_check argument, this function may return a non-boolean value
  #                     that evaluates to false (e.g.) 0, so use the === operator for testing the
  #                     return value.
  def has_filter(tag, function_to_check = false)
    # global $wp_filter;

    return false if Railspress.GLOBAL.wp_filter[ tag ].blank?

    Railspress.GLOBAL.wp_filter[ tag ].has_filter( tag, function_to_check )
  end

  # Call the functions added to a filter hook.
  #
  # The callback functions attached to filter hook $tag are invoked by calling
  # this function. This function can be used to create a new filter hook by
  # simply calling this function with the name of the new hook specified using
  # the $tag parameter.
  #
  # The function allows for additional arguments to be added and passed to hooks.
  #
  #     // Our filter callback function
  #     function example_callback( $string, $arg1, $arg2 ) {
  #         // (maybe) modify $string
  #         return $string;
  #     }
  #     add_filter( 'example_filter', 'example_callback', 10, 3 );
  #
  #     /*
  #      * Apply the filters by calling the 'example_callback' function we
  #      * "hooked" to 'example_filter' using the add_filter() function above.
  #      * - 'example_filter' is the filter hook $tag
  #      * - 'filter me' is the value being filtered
  #      * - $arg1 and $arg2 are the additional arguments passed to the callback.
  #     $value = apply_filters( 'example_filter', 'filter me', $arg1, $arg2 );
  #
  # @global array $wp_filter         Stores all of the filters.
  # @global array $wp_current_filter Stores the list of current filters with the current one last.
  #
  # @param [String] tag     The name of the filter hook.
  # @param value   The value on which the filters hooked to `tag` are applied on.
  # @param args Additional variables passed to the functions hooked to `tag`.
  # @return The filtered value after all hooked functions are applied to it.
  def apply_filters(tag, value, *args)
    # global $wp_filter, $wp_current_filter

    #  Do 'all' actions first.
    if Railspress.GLOBAL.wp_filter['all']
      Railspress.GLOBAL.wp_current_filter << tag
      _wp_call_all_hook(args)
    end
    unless Railspress.GLOBAL.wp_filter[tag]
      if Railspress.GLOBAL.wp_filter['all']
        Railspress.GLOBAL.wp_current_filter.pop
      end
      return value
    end
    unless Railspress.GLOBAL.wp_filter['all']
      Railspress.GLOBAL.wp_current_filter << tag
    end
    filtered = Railspress.GLOBAL.wp_filter[tag].apply_filters(value, args)
    Railspress.GLOBAL.wp_current_filter.pop
    filtered
  end

  module_function :apply_filters

  # Execute functions hooked on a specific filter hook, specifying arguments in an array.
  #
  # @see apply_filters() This function is identical, but the arguments passed to the
  # functions hooked to `$tag` are supplied using an array.
  #
  # @global array $wp_filter         Stores all of the filters
  # @global array $wp_current_filter Stores the list of current filters with the current one last
  #
  # @param [string] tag  The name of the filter hook.
  # @param [array]  args The arguments supplied to the functions hooked to $tag.
  # @return [mixed] The filtered value after all hooked functions are applied to it.
  def apply_filters_ref_array( tag, args )
    # global $wp_filter, $wp_current_filter;

    # Do 'all' actions first
    if ( isset( Railspress.GLOBAL.wp_filter['all'] ) )
      Railspress.GLOBAL.wp_current_filter << tag
      all_args            = func_get_args()
      _wp_call_all_hook(all_args )
    end

    if (!isset(Railspress.GLOBAL.wp_filter[$tag]))
      if (isset(Railspress.GLOBAL.wp_filter['all']))
        array_pop(Railspress.GLOBAL.wp_current_filter)
      end
      return $args[0]
    end

    if (!isset(Railspress.GLOBAL.wp_filter['all']))
      Railspress.GLOBAL.wp_current_filter << tag
    end

    filtered = Railspress.GLOBAL.wp_filter[tag].apply_filters(args[0], args)

    array_pop(Railspress.GLOBAL.wp_current_filter)

    return filtered
  end

  # Hooks a function on to a specific action.
  #
  # Actions are the hooks that the WordPress core launches at specific points
  # during execution, or when specific events occur. Plugins can specify that
  # one or more of its PHP functions are executed at these points, using the
  # Action API.
  #
  # @since 1.2.0
  #
  # @param [string]   tag             The name of the action to which the $function_to_add is hooked.
  # @param [callable] function_to_add The name of the function you wish to be called.
  # @param [int]      priority        Optional. Used to specify the order in which the functions
  #                                   associated with a particular action are executed. Default 10.
  #                                   Lower numbers correspond with earlier execution,
  #                                   and functions with the same priority are executed
  #                                   in the order in which they were added to the action.
  # @param [int]      accepted_args   Optional. The number of arguments the function accepts. Default 1.
  # @return true Will always return true.
  def add_action(tag, function_to_add, priority = 10, accepted_args = 1 )
    add_filter(tag, function_to_add, priority, accepted_args )
  end


  # Execute functions hooked on a specific action hook.
  #
  # This function invokes all functions attached to action hook `$tag`. It is
  # possible to create new action hooks by simply calling this function,
  # specifying the name of the new hook using the `$tag` parameter.
  #
  # You can pass extra arguments to the hooks, much like you can with apply_filters().
  #
  # @global array $wp_filter         Stores all of the filters
  # @global array $wp_actions        Increments the amount of times action was triggered.
  # @global array $wp_current_filter Stores the list of current filters with the current one last
  #
  # @param [string] tag     The name of the action to be executed.
  # @param [mixed]  arg,... Optional. Additional arguments which are passed on to the
  #                         functions hooked to the action. Default empty.
  def do_action(tag, *arg )
    # global $wp_filter, $wp_actions, $wp_current_filter
    # TODO continue
  end

  # Call the 'all' hook, which will process the functions hooked into it.
  #
  # The 'all' hook passes all of the arguments or parameters that were used for
  # the hook, which this function was called for.
  #
  # @param args The collected parameters from the hook that was called.
  private def _wp_call_all_hook(args)
    # global wp_filter  Stores all of the filters
    Railspress.GLOBAL.wp_filter['all'].do_all_hook(args)
  end

  # TODO _wp_filter_build_unique_id

end
