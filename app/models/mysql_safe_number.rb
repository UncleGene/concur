class MysqlSafeNumber < ActiveRecord::Base
  def self.find_or_create(val)
    where(value: val).first_or_create
  rescue ActiveRecord::RecordNotUnique
    retry
  rescue ActiveRecord::StatementInvalid => e
    retry if e.message =~ /Deadlock/ # Thank you, MySQL!
    raise
  end
end
