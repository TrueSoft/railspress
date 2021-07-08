=begin
 * Query API: WP_Hook class
 *
 * Core class used to implement action and filter hook functionality.
 *
 * file wp-includes\class-wp-hook.php
=end
class Railspress::WPHook

  # Hook callbacks.
  #
  # @var array
  attr_accessor :callbacks

  # The priority keys of actively running iterations of a hook.
  #
  # @var array
  attr_accessor :iterations

  # The current priority of actively running iterations of a hook.
  #
  # @var array
  attr_accessor :current_priority

  # Number of levels this hook can be recursively called.
  #
  # @var int
  attr_accessor :nesting_level

  # Flag for if we're current doing an action, rather than a filter.
  #
  # @var bool
  attr_accessor :doing_action

  def initialize
    @callbacks = {}
    @iterations = {}
    @current_priority = {}
    @nesting_level = 0
    @doing_action = false
  end

  # Hooks a function or method to a specific filter action.
  #
  # @param [string]   tag             The name of the filter to hook the $function_to_add callback to.
  # @param [callable] function_to_add The callback to be run when the filter is applied.
  # @param [int]      priority        The order in which the functions associated with a
  #                                   particular action are executed. Lower numbers correspond with
  #                                   earlier execution, and functions with the same priority are executed
  #                                   in the order in which they were added to the action.
  # @param [int]      accepted_args   The number of arguments the function accepts.
  def add_filter( tag, function_to_add, priority, accepted_args )
    idx =  _wp_filter_build_unique_id( tag, function_to_add, priority )
    priority_existed = !@callbacks[ priority ].nil?

    @callbacks[ priority ] = [] unless priority_existed
    @callbacks[ priority ] << {function: function_to_add, accepted_args: accepted_args}

    # if we're adding a new priority to the list, put them back in sorted order
    #		if ( ! $priority_existed && count( $this->callbacks ) > 1 ) {
    #			ksort( $this->callbacks, SORT_NUMERIC );
    #		}

    resort_active_iterations( priority, priority_existed ) if @nesting_level > 0
  end

  def resort_active_iterations(new_priority = false, priority_existed = false)
    # TODO resort_active_iterations
  end

  # TODO remove_filter has_filter has_filters remove_all_filters
  # Calls the callback functions added to a filter hook.
  #
  # @param [mixed] value The value to filter.
  # @param [array] args  Arguments to pass to callbacks.
  # @return mixed The filtered value after all hooked functions are applied to it.
  def apply_filters( value, args )
    return value if @callbacks.blank?

    @nesting_level += 1
    @iterations[@nesting_level] = @callbacks.keys
    num_args = args.length

    @iterations[@nesting_level].each do |priority|
      @current_priority[@nesting_level] = priority

      @callbacks[priority].each do |the_|

        args[0] = value unless @doing_action

        # Avoid the array_slice if possible.
        if the_[:accepted_args] == 0
          value = the_[:function].call
        elsif the_[:accepted_args] >= num_args
          value = the_[:function].call(args)
        else
          value = the_[:function].call(args.slice(0, the_[:accepted_args]))
        end
      end
    end
    @iterations.delete(@nesting_level)
    @current_priority.delete(@nesting_level)

    @nesting_level -= 1

    value
  end


  # Executes the callback functions hooked on a specific action hook.
  #
  # @param [mixed] $args Arguments to pass to the hook callbacks.
  def do_action( args )
    @doing_action = true
    apply_filters( '', args )

    # If there are recursive calls to the current action, we haven't finished it until we get to the last one.
    @doing_action = false if @nesting_level == 0
  end

  # Processes the functions hooked into the 'all' hook.
  #
  # @param [array] args Arguments to pass to the hook callbacks. Passed by reference.
  def do_all_hook( *args )
    @nesting_level += 1
# TODO continue
#		$this->iterations[ $nesting_level ] = array_keys( $this->callbacks );
#
#		do {
#			$priority = current( $this->iterations[ $nesting_level ] );
#			foreach ( $this->callbacks[ $priority ] as $the_ ) {
#				call_user_func_array( $the_['function'], $args );
#			}
#		} while ( false !== next( $this->iterations[ $nesting_level ] ) );
#
#		unset( $this->iterations[ $nesting_level ] );
    @nesting_level -= 1
  end

  def _wp_filter_build_unique_id(tag, function, priority)
    return function if function.is_a?(String)

    # TODO continue
    if !function.is_a?(Array) # is_object( function )
      # Closures are currently implemented as objects.
      function = [function, '']
    else
      # function = (array) function;
    end

    if !function.is_a?(Array) # is_object( function[0] )
      # Object class calling.
      ( function[0].object_id.to_s ) + function[1] # spl_object_hash
    elsif function[0].is_a? String
      # Static calling.
      function[0] + '::' + function[1]
    end

  end
end