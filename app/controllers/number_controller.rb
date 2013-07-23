class NumberController < ApplicationController
  before_filter :init_number

  def view
    @number ||= Number.first || Number.find_or_create_by_value(0)
    session[:nid] = @number.id
  end
  allow_get :view

  def vote
    increment if recognized?
    redirect_to :action => :view
  end
  allow_get :vote

  def vote_more
    increment if recognized?
  end
  allow_get :vote_more

  def do_vote
    increment if recognized?
  end

protected
  def init_number
    @number = Number.find(session[:nid]) if session[:nid]
  end

private
  def recognized?
    !!session[:nid]
  end

  def increment
    Number.increment_counter :value, @number
  end
end
