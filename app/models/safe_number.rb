class SafeNumber < ActiveRecord::Base
  def self.first_or_create_where(*args)
    where(*args).first_or_create
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
