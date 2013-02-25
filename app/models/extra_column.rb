class ExtraColumn < ActiveRecord::Base
  def self.columns
    super.reject{ |c| c.name == 'extra' } 
  end
end
