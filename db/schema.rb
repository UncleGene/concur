# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130225021040) do

  create_table "constrained_numbers", :force => true do |t|
    t.integer "value"
  end

  add_index "constrained_numbers", ["value"], :name => "index_constrained_numbers_on_value", :unique => true

  create_table "dogs", :force => true do |t|
  end

  create_table "extra_columns", :force => true do |t|
    t.integer "value"
    t.string  "extra"
  end

  create_table "heads", :force => true do |t|
    t.integer "dog_id"
  end

  create_table "legs", :force => true do |t|
    t.integer "dog_id"
  end

  create_table "mysql_safe_numbers", :force => true do |t|
    t.integer "value"
  end

  add_index "mysql_safe_numbers", ["value"], :name => "index_mysql_safe_numbers_on_value", :unique => true

  create_table "numbers", :force => true do |t|
    t.integer "value"
  end

  create_table "safe_numbers", :force => true do |t|
    t.integer "value"
  end

  add_index "safe_numbers", ["value"], :name => "index_safe_numbers_on_value", :unique => true

  create_table "validated_numbers", :force => true do |t|
    t.integer "value"
  end

end
