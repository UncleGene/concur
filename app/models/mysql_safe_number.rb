class MysqlSafeNumber < ActiveRecord::Base
  
  def self.find_or_create(value)
    find_or_create_by_value(value)
  rescue ActiveRecord::RecordNotUnique
    find_by_value(value)
  rescue ActiveRecord::StatementInvalid => e
    retry if e.message =~ /Deadlock/ # Thank you, MySQL!
    raise
  end

end
