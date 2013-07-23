require 'active_support/concern'
module ProtectFromGets
  extend ActiveSupport::Concern

  module ClassMethods
    def protect_from_gets
      append_before_filter :protect_from_get
    end

    def allow_get(*actions)
      @allowed ||= []
      @allowed |= actions.map(&:to_s)
    end

    def can_get? action
      @allowed ||= []
      @allowed.include? action
    end
  end

protected
  def protect_from_get
    return unless request.get?
    return if self.class.can_get? action_name
    head :status => :forbidden
  end
end

ActionController::Base.send :include, ProtectFromGets
