require_dependency "railspress/application_controller"

module Railspress
  class OptionsController < ApplicationController
    before_action :check_signed_in

    def index
      @options = get_display_options
      @option = Railspress::Option.new
      @options << @option
      if Railspress.generate_breadcrumb
        @breadcrumb = {t('railspress.option.index.title') => main_app.admin_options_path}
      end
    end

    def new
      @options = get_display_options
      @option = Railspress::Option.new
      @options << @option # if @option.new_record?
      if Railspress.generate_breadcrumb
        @breadcrumb = {t('railspress.option.index.title') => main_app.admin_options_path}
        @breadcrumb[t('railspress.option.new.title')] = nil
      end
      render action: :index
    end

    def create
      @option = Railspress::Option.new model_params
      if @option.save
        # ch_migr @option.create_activity :create, owner: current_user, parameters: {option_name: @option.option_name, option_value: @option.option_value}
        helpers.add_option  @option.option_name, @option.option_value
        redirect_to(main_app.admin_options_path, notice: t('railspress.option.create.save'))
      else
        @options = get_display_options
        @options << @option # if @option.new_record?
        if Railspress.generate_breadcrumb
          @breadcrumb = {t('railspress.option.index.title') => main_app.admin_options_path}
          @breadcrumb[t('railspress.option.new.title')] = nil
        end
        render action: :index
      end
    rescue ActiveRecord::RecordNotUnique
      flash.now[:error] = t('railspress.option.create.error_not_unique', name: @option.option_name)
      @options = get_display_options
      render action: :index
    end

    def edit
      @options = get_display_options
      @option = Railspress::Option.find(params[:id])
      if Railspress.generate_breadcrumb
        @breadcrumb = {t('railspress.option.index.title') => main_app.admin_options_path}
        @breadcrumb[t('railspress.option.edit.title')] = nil
      end
      render action: :index
    rescue ActiveRecord::RecordNotFound
      flash[:error] = t('railspress.option.edit.error_not_found')
      redirect_to action: :index
    end

    def update
      @option = Railspress::Option.find(params[:id])
      if @option.update_attributes(model_params)
        # ch_migr  @option.create_activity :update, owner: current_user, parameters: {option_name: @option.option_name, option_value: @option.option_value}
        helpers.update_option  @option.option_name, @option.option_value
        redirect_to(main_app.admin_options_path, notice: t('railspress.option.update.save'))
      else
        @options = get_display_options
        render action: :index
      end
    end

    def destroy
      @option = Railspress::Option.find(params[:id])
      # ch_migr  @option.create_activity :destroy, owner: current_user, parameters: {option_name: @option.option_name, option_value: @option.option_value}
      if @option.destroy
        helpers.delete_option @option.option_name
        redirect_to(main_app.admin_options_path, notice: t('railspress.option.destroy'))
      else
        @options = get_display_options
        @option = Railspress::Option.new
        render action: :index
      end
    end

    private

    def check_signed_in
      event_check_si = Railspress.main_app_hook.on_check_signed_in
      if !event_check_si.nil? && !event_check_si.on(:signed_in?)
        redirect_to main_app.root_url, alert: (event_check_si.temp_message || 'You need to be signed in to access this page.')
      end
    end

    def get_display_options
      opts = []
      opts += Railspress::Option.where(option_name: READONLY_OPTIONS).to_a
      opts += Railspress::Option.where(option_name: EDITABLE_OPTIONS).to_a
      readonly_simple = Railspress.TS_READONLY_OPTIONS.reject {|on| on.index('*')}
      readonly_wildcards = Railspress.TS_READONLY_OPTIONS.select {|on| on.index('*')}
      opts += Railspress::Option.where(option_name: readonly_simple).to_a
      readonly_wildcards.each do |opt_name|
        opts += Railspress::Option.where('option_name LIKE ?', opt_name.gsub(/\*/, '%')).to_a
      end
      editable_simple = Railspress.TS_EDITABLE_OPTIONS.reject {|on| on.index('*')}
      editable_wildcards = Railspress.TS_EDITABLE_OPTIONS.select {|on| on.index('*')}
      opts += Railspress::Option.where(option_name: editable_simple).to_a
      editable_wildcards.each do |opt_name|
        opts += Railspress::Option.where('option_name LIKE ?', opt_name.gsub(/\*/, '%')).to_a
      end
      opts
    end

    def model_params
      params.require(:railspress_option).permit([:option_id, :option_name, :option_value, :autoload])
    end

  end
end
