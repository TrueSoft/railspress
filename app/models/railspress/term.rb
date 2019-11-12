module Railspress
  class Term < ApplicationRecord
    self.table_name = self.prefix_table_name('terms')

    belongs_to :taxonomy, class_name: Railspress::Taxonomy.name, foreign_key: 'term_id'

    before_save :set_slug_value
    validates :slug, uniqueness: true

    # Stores the term object's sanitization level.
    #
    # Does not correspond to a database field.
    attr_accessor :filter_str # default 'raw'

    def set_slug_value
      self.slug = self.name.parameterize
    end

    # Sanitizes term fields, according to the filter type provided.
    #
    # @param [string] $filter Filter context. Accepts 'edit', 'db', 'display', 'attribute', 'js', 'raw'.
    def filter( filter_str )
      # TODO how to access helper method
      # sanitize_term(self, self.taxonomy, filter_str )
    end

    # Converts an object to array.
    #
    # @return array Object as array.
    def to_array
      get_object_vars(self)
    end
  end
end