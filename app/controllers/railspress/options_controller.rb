require_dependency "railspress/application_controller"

module Railspress
  class OptionsController < ApplicationController
    def index
      @options = get_display_options
      @option = Railspress::Option.new
      @options << @option
    end

    def new
      @options = get_display_options
      @option = Railspress::Option.new
      @options << @option # if @option.new_record?
      @breadcrumb[t('railspress.option.new.title')] = nil
      render action: :index
    end

    def create
      @option = Railspress::Option.new model_params
      if @option.save
        @option.create_activity :create, owner: current_user, parameters: {option_name: @option.option_name, option_value: @option.option_value}
        redirect_to({action: :index}, notice: "Salvarea a fost efectuata cu succes.")
      else
        @options = get_display_options
        @options << @option # if @option.new_record?
        @breadcrumb[t('railspress.option.new.title')] = nil
        render action: :index
      end
    rescue ActiveRecord::RecordNotUnique
      flash.now[:error] = "Optiunea cu numele #{@option.option_name} exista deja."
      @options = get_display_options
      render action: :index
    end

    private

    def get_display_options
      opts = []
      opts += Railspress::Option.where(option_name: READONLY_OPTIONS).to_a
      opts += Railspress::Option.where(option_name: EDITABLE_OPTIONS).to_a
      readonly_simple = []#Rails.configuration.TS_READONLY_OPTIONS.reject {|on| on.index('*')}
      readonly_wildcards = []#Rails.configuration.TS_READONLY_OPTIONS.select {|on| on.index('*')}
      opts += Railspress::Option.where(option_name: readonly_simple).to_a
      readonly_wildcards.each do |opt_name|
        opts += Railspress::Option.where('option_name LIKE ?', opt_name.gsub(/\*/, '%')).to_a
      end
      editable_simple = []# Rails.configuration.TS_EDITABLE_OPTIONS.reject {|on| on.index('*')}
      editable_wildcards = []#Rails.configuration.TS_EDITABLE_OPTIONS.select {|on| on.index('*')}
      opts += Railspress::Option.where(option_name: editable_simple).to_a
      editable_wildcards.each do |opt_name|
        opts += Railspress::Option.where('option_name LIKE ?', opt_name.gsub(/\*/, '%')).to_a
      end
      opts
    end

    def breadcrumb_items
      super.merge(t('railspress.option.index.title') => options_path)
    end

    def model_params
      params.require(:railspress_option).permit([:option_id, :option_name, :option_value, :autoload])
    end

  end
end
