module Railspress
  class Relationship < ApplicationRecord
    self.table_name = self.prefix_table_name('term_relationships')
    self.primary_key = nil
    after_save :increment_term_use_count
    before_destroy :decrement_term_use_count

    belongs_to :post, class_name: Railspress::Post.name, foreign_key: :object_id
    belongs_to :category, class_name: Railspress::Category.name, foreign_key: :object_id
    belongs_to :menuitem, class_name: Railspress::NavMenuItem.name, foreign_key: :object_id
    belongs_to :taxonomy, class_name: Railspress::Taxonomy.name, foreign_key: :term_taxonomy_id

    def increment_term_use_count
      self.taxonomy.update_attribute(:count, self.taxonomy.count + 1) if self.taxonomy.present?
    end

    def decrement_term_use_count
      self.taxonomy.update_attribute(:count, self.taxonomy.count - 1) if self.taxonomy.present?
    end
  end
end