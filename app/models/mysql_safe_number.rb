class MysqlSafeNumber < ActiveRecord::Base
  def self.first_or_create_where(*args)
    where(*args).first_or_create
  rescue ActiveRecord::RecordNotUnique
    retry
  rescue ActiveRecord::StatementInvalid => e
    retry if e.message =~ /Deadlock/ # Thank you, MySQL!
    raise
  end
end
