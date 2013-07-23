class ExtraColumn < ActiveRecord::Base
  def self.column
    super.reject{ |c| c.name == 'extra' } 
  end
end
