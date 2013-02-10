class SafeNumber < ActiveRecord::Base

  def self.find_or_create(value)
    find_or_create_by_value(value)
  rescue ActiveRecord::RecordNotUnique
    find_by_value(value)
  end

end
