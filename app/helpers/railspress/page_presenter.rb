class Railspress::PagePresenter

  def self.for
    [:ts_childpages]
  end

  def initialize(attributes, content, additional_attributes)
    @content = content
    @attributes = attributes
    @additional_attributes = additional_attributes
  end

  def content
    @content
  end

  def attributes
    @attributes.merge({page: @additional_attributes[:page]} )
  end
end