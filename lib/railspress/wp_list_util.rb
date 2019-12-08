=begin
 * WordPress List utility class
 *
 * file wp-includes\class-wp-list-util.php
=end

=begin
 * List utility.
 *
 * Utility class to handle operations on an array of objects.
=end
class Railspress::WP_List_Util
  # The input array.
  attr_accessor :input

  # The output array.
  attr_accessor :output

  # Temporary arguments for sorting.
  attr_accessor :orderby

  # Constructor.
  #
  # Sets the input array.
  #
  # @param [array] input Array to perform operations on.
  def initialize(input)
    @output = @input = input
  end

  # Filters the list, based on a set of key => value arguments.
  #
  # @param [array]  args     Optional. An array of key => value arguments to match
  #                          against each object. Default empty array.
  # @param [string] operator Optional. The logical operation to perform. 'AND' means
  #                          all elements from the array must match. 'OR' means only
  #                          one element needs to match. 'NOT' means no elements may
  #                          match. Default 'AND'.
  # @return array Array of found values.
  def filter(args = {}, operator = 'AND')
    return @output if args.empty?

    operator = operator.upcase

    return {} unless ['AND', 'OR', 'NOT'].include? operator

    count = args.size
    filtered = {}

    @output.each_pair do |key, obj|
      to_match = obj

      matched = 0
      args.each_pair do |m_key, m_value|
        if to_match.respond_to?(m_key.to_sym) && m_value == to_match.send(m_key.to_sym)
          matched += 1
        end
      end

      if ('AND' == operator && matched == count) ||
          ('OR' == operator && matched > 0) ||
          ('NOT' == operator && 0 == matched)
        filtered[key] = obj
      end
    end
    @output = filtered
  end

  # Plucks a certain field out of each object in the list.
  #
  # This has the same functionality and prototype of
  # array_column() (PHP 5.5) but also supports objects.
  #
  # @param [int|string] field     Field from the object to place instead of the entire object
  # @param [int|string] index_key Optional. Field from the object to use as keys for the new array.
  #                               Default null.
  # @return [array] Array of found values. If `$index_key` is set, an array of found values with keys
  #                 corresponding to `$index_key`. If `$index_key` is null, array keys from the original
  #                 `$list` will be preserved in the results.
  def pluck(field, index_key = nil)
    unless index_key
      newlist = {}
      # This is simple. Could at some point wrap array_column()
      # if we knew we had an array of arrays.
      @output.each_pair do |key, value|
        if value.is_a? Hash
          newlist[key] = value[field]
        else
          newlist[key] = value.send(field.to_sym)
        end
      end
      return @output = newlist
    end

    newlist = {}
    # When index_key is not set for a particular item, push the value
    # to the end of the stack. This is how array_column() behaves.
    @output.each_value do |value|
      if !value.is_a? Hash
        if value.send(index_key)
          newlist[value.send(index_key)] = value.send(field.to_sym)
        else
          newlist << value.send(field.to_sym)
        end
      else
        if value[index_key]
          newlist[value[index_key]] = value[field]
        else
          newlist << value[field]
        end
      end
    end
    @output = newlist
  end

  # TODO def sort

  # TODO def sort_callback

end