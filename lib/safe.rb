module Safe
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def safe_find_or_create(opts)
      send('find_or_create_by_' + opts.keys.join('_and_'), *opts.values)
    rescue ActiveRecord::RecordNotUnique
      send('find_by_' + opts.keys.join('_and_'), *opts.values)
    rescue ActiveRecord::StatementInvalid => e
      retry if e.message =~ /Deadlock/ # Thank you, MySQL!
      raise
    end

    def safe_create(*args)
      create(*args)
    rescue ActiveRecord::RecordNotUnique
      new(*args)
    rescue ActiveRecord::StatementInvalid => e
      retry if e.message =~ /Deadlock/ # Thank you, MySQL!
      raise
    end
  end
end
