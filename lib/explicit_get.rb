require 'active_support/concern'
module ExplicitGet
  extend ActiveSupport::Concern

  module ClassMethods
    def protect_from_gets
      append_before_filter :block_gets
    end

    def allow_get sym
      skip_before_filter :block_gets, :only => sym
    end

    def allow_gets *args
      skip_before_filter :block_gets, *args
    end
  end

protected
  def block_gets
    return unless request.get?
    head :status => :forbidden
  end
end

ActionController::Base.send :include, ExplicitGet
