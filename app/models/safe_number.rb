class SafeNumber < ActiveRecord::Base
  def self.find_or_create(val)
    where(value: val).first_or_create
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
