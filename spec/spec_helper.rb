load './spec/support/_coverage.rb' if ENV['COVERAGE']
require 'rubygems'
require 'bundler'
Bundler.require

SPEC_ROOT = File.expand_path File.dirname(__FILE__)
Dir["#{SPEC_ROOT}/support/**/*.rb"].each { |f| require f unless File.basename(f) =~ /^_/ }

database_host = ENV['DB_HOST'] || 'localhost'
database_name = ENV['DB_NAME'] || 'nobrainer_test'

if ENV['TEST_ENV_NUMBER']
  DB_SUFFIX = "_N#{ENV['TEST_ENV_NUMBER']}"
  database_name = database_name + DB_SUFFIX

  class NoBrainer::QueryRunner::RunOptions < NoBrainer::QueryRunner::Middleware
    class << self
      alias_method :with_database_orig, :with_database
      def with_database(db_name, &block)
        db_name = db_name + DB_SUFFIX unless db_name =~ /#{DB_SUFFIX}$/
        with_database_orig(db_name, &block)
      end
    end
  end

  module NoBrainer::Document::StoreIn::ClassMethods
    alias_method :database_name_orig, :database_name
    def database_name
      db_name = database_name_orig
      db_name = db_name + DB_SUFFIX if db_name && db_name !~ /#{DB_SUFFIX}$/
      db_name
    end
  end
end

I18n.enforce_available_locales = true rescue nil

NoBrainer::Document::Id.__send__(:remove_const, :DEFAULT_PK_NAME)
NoBrainer::Document::Id.__send__(:const_set,    :DEFAULT_PK_NAME, :_id_)

RSpec.configure do |config|
  config.color = true
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.include ModelsHelper
  config.include CallbacksHelper

  config.before(:each) do
    NoBrainer.configure do |c|
      c.reset!
      c.rethinkdb_url = "rethinkdb://#{database_host}/#{database_name}"
      c.durability = :soft
      c.logger.level = Logger::DEBUG if ENV['DEBUG']
    end

    NoBrainer.purge!
    NoBrainer::Loader.cleanup
  end
end
