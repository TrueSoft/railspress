=begin
 * A class for displaying various tree-like structures.
 *
 * Extend the Walker class to use it, see examples below. Child classes
 * do not need to implement all of the abstract methods in the class. The child
 * only needs to implement the methods that are needed.
 *
 * file wp-includes\class-wp-walker.php
=end
class Railspress::Walker

  # What the class handles.
  #
  # @var string
  attr_accessor :tree_type

  # DB fields to use.
  #
  # @var array
  attr_accessor :db_fields

  # Max number of pages walked by the paged walker
  #
  # @var int
  attr_accessor :max_pages

  # Whether the current element has children or not.
  #
  # To be used in start_el().
  #
  # @var bool
  attr_accessor :has_children

  def initialize
    @max_pages = 1
  end

  # Starts the list before the elements are added.
  #
  # The $args parameter holds additional values that may be used with the child
  # class methods. This method is called at the start of the output list.
  #
  # @param [string] output Used to append additional content (passed by reference).
  # @param [int]    depth  Depth of the item.
  # @param [array]  args   An array of additional arguments.
  def start_lvl(output, depth = 0, args = {})
  end

  # Ends the list of after the elements are added.
  #
  # The $args parameter holds additional values that may be used with the child
  # class methods. This method finishes the list at the end of output of the elements.
  #
  # @param [string] output Used to append additional content (passed by reference).
  # @param [int]    depth  Depth of the item.
  # @param [array]  args   An array of additional arguments.
  def end_lvl(output, depth = 0, args = {})
  end

  # Start the element output.
  #
  # The $args parameter holds additional values that may be used with the child
  # class methods. Includes the element output also.
  #
  # @since 2.1.0
  # @abstract
  #
  # @param [string] output            Used to append additional content (passed by reference).
  # @param [object] object            The data object.
  # @param [int]    depth             Depth of the item.
  # @param [array]  args              An array of additional arguments.
  # @param [int]    current_object_id ID of the current item.
  def start_el(output, object, depth = 0, args = {}, current_object_id = 0)
  end

  # Ends the element output, if needed.
  #
  # The $args parameter holds additional values that may be used with the child class methods.
  #
  # @since 2.1.0
  # @abstract
  #
  # @param [string] output Used to append additional content (passed by reference).
  # @param [object] object The data object.
  # @param [int]    depth  Depth of the item.
  # @param [array]  args   An array of additional arguments.
  def end_el(output, object, depth = 0, args = {})
  end

  # Traverse elements to create list from elements.
  #
  # Display one element if the element doesn't have any children otherwise,
  # display the element and its children. Will only traverse up to the max
  # depth and no ignore elements under that depth. It is possible to set the
  # max depth to include all depths, see walk() method.
  #
  # This method should not be called directly, use the walk() method instead.
  #
  # @since 2.5.0
  #
  # @param [object] element           Data object.
  # @param [array]  children_elements List of elements to continue traversing (passed by reference).
  # @param [int]    max_depth         Max depth to traverse.
  # @param [int]    depth             Depth of current element.
  # @param [array]  args              An array of arguments.
  # @param [string] output            Used to append additional content (passed by reference).
  def display_element(element, children_elements, max_depth, depth, args, output)
    return unless element

    id_field = @db_fields[:id]
    id = element.send(id_field)

    # display this element
    @has_children = !children_elements[id].blank?
    if args[0].is_a? Hash
      args[0][:has_children] = @has_children # Back-compat.
    end

    self.start_el(output, element, depth, args[0] || {})
    newlevel = nil
    # descend only when the depth is right and there are childrens for this element
    if (max_depth == 0 || max_depth > depth + 1) && children_elements[id]
      children_elements[id].each do |child|
        if newlevel.nil?
          newlevel = true
          # start the child delimiter
          self.start_lvl(output, depth, args[0] || {})
        end
        display_element(child, children_elements, max_depth, depth + 1, args, output)
      end
      children_elements.delete(id)
    end

    if newlevel
      # end the child delimiter
      self.end_lvl(output, depth, args[0] || {})
    end

    # end this element
    self.end_el(output, element, depth, args[0] || {})
  end

  # Calculates the total number of root elements.
  #
  # @param [array] elements Elements to list.
  # @return int Number of root elements.
  def get_number_of_root_elements(elements)
    num = 0
    parent_field = @db_fields[:parent]
    elements.each do |e|
      num += 1 if e.send(parent_field) == 0
    end
    num
  end

  # Display array of elements hierarchically.
  #
  # Does not assume any existing order of elements.
  #
  # $max_depth = -1 means flatly display every element.
  # $max_depth = 0 means display all levels.
  # $max_depth > 0 specifies the number of display levels.
  #
  # @param [array] elements  An array of elements.
  # @param [int]   max_depth The maximum hierarchical depth.
  # @return [string] The hierarchical item output.
  def walk(elements, max_depth, *args)
    output = ''

    # invalid parameter or nothing to walk
    return output if max_depth < -1 || elements.blank?

    parent_field = @db_fields[:parent]

    # flat display
    if -1 == max_depth
      empty_array = {}
      elements.each do |e|
        display_element(e, empty_array, 1, 0, args, output)
      end
      return output
    end

    # Need to display in hierarchical order.
    # Separate elements into two buckets: top level and children elements.
    # Children_elements is two dimensional array, eg.
    # Children_elements[10][] contains all sub-elements whose parent is 10.
    top_level_elements = []
    children_elements = {}
    elements.each do |e|
      if e.send(parent_field).blank? || e.send(parent_field) == 0
        top_level_elements << e
      else
        children_elements[e.send(parent_field)] ||= []
        children_elements[e.send(parent_field)] << e
      end
    end

    # When none of the elements is top level.
    # Assume the first one must be root of the sub elements.
    if top_level_elements.blank?
      root = elements.first

      top_level_elements = []
      children_elements = {}
      elements.each do |e|
        if root.send(parent_field) == e.send(parent_field)
          top_level_elements << e
        else
          children_elements[e.send(parent_field).to_i] ||= []
          children_elements[e.send(parent_field).to_i] << e
        end
      end
    end

    top_level_elements.each do |e|
      display_element(e, children_elements, max_depth, 0, args, output)
    end

    # If we are displaying all levels, and remaining children_elements is not empty,
    # then we got orphans, which should be displayed regardless.
    if max_depth == 0 && !children_elements.empty?
      empty_array = {}
      children_elements.values.each do |orphans|
        orphans.each do |op|
          display_element(op, empty_array, 1, 0, args, output)
        end
      end
    end
    output
  end

  # paged_walk() - produce a page of nested elements
  #
  # Given an array of hierarchical elements, the maximum depth, a specific page number,
  # and number of elements per page, this function first determines all top level root elements
  # belonging to that page, then lists them and all of their children in hierarchical order.
  #
  # $max_depth = 0 means display all levels.
  # $max_depth > 0 specifies the number of display levels.
  #
  # @param [array] elements
  # @param [int]   max_depth The maximum hierarchical depth.
  # @param [int]   page_num The specific page number, beginning with 1.
  # @param [int]   per_page
  # @return string XHTML of the specified page of elements
  def paged_walk(elements, max_depth, page_num, per_page)
    # TODO continue
  end

  # Unset all the children for a given top level element.
  #
  # @param [object] e
  # @param [array]  children_elements
  def unset_children(e, children_elements)
    return if !e || !children_elements

    id_field = @db_fields[:id]
    id = e.send(id_field)
    if children_elements[id].is_a? Array
      children_elements[id].each do |child|
        unset_children(child, children_elements)
      end
    end
    children_elements.delete(id)
  end
end