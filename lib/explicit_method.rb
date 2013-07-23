require 'active_support/concern'
module ExplicitMethod
  extend ActiveSupport::Concern

  included do
    append_before_filter :validate_method
  end

  ALL = %w(GET PUT POST DELETE)
  #allow_method :all, :action
  #allow_methods :put, :options, :action
  module ClassMethods
    def allow_method(method, action)
      allow_methods(method, action)
      @allowed |= actions
    end

    def allow_methods(*args)
      raise 'Please provide at least one method and action name' if args.size < 2
      @allowed ||= {}
      action = args.pop.to_s
      methods = args.map(&:to_s).map(&:upcase) + ['HEAD'] 
      methods = methods - ['ALL'] + ALL if methods.include? 'ALL'
      @allowed[action] = methods
    end
    
    def allowed_for action
      @allowed.action
    end
    def can_get? action
      @allowed ||= []
      @allowed.include? action.to_sym
    end
  end

protected
  def validate_method    
    return unless (methods = class.allowed_for action_name)
    response.header['Allow'] = methods.join ', '
    # Handle HEAD separately. Should always be allowed?
    return if methods.include? request.method

    head :status => :forbidden
  end
end
