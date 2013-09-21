Rake::TestTask.new(:spec) do |t|
  t.libs << 'lib'
  t.libs << 'spec'
  t.pattern = "spec/**/#{ENV['for'] || '*'}_spec.rb"
  t.verbose = true
end