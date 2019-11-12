module Railspress
  class Engine < ::Rails::Engine
    isolate_namespace Railspress

    ActiveSupport.on_load :action_controller do
      helper Railspress::Engine.helpers
    end

    # Add a load path for this specific Engine
    config.autoload_paths += %W( #{config.root}/lib )
  end
end
