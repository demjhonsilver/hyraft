# test/integration/database/migration_test.rb
require_relative "../../test_helper"

class MigrationTest < Minitest::Test
  def setup
    skip_if_no_database
  end
  
  def test_migrations_can_run_successfully
    # Remove the duplicate skip condition - setup already handles it
    db = SequelConnection.db
    assert db, "Database connection should be established"
    
    assert db.tables.include?(:articles), "Articles table should exist from migrations"
    
    columns = db.schema(:articles).map { |col| col.first }

    assert_includes columns, :id
    assert_includes columns, :title
    assert_includes columns, :content
  end
  
  def test_database_connection_works_for_migrations
    db = SequelConnection.db
    assert db.test_connection
  end

  private

  def skip_if_no_database
    if ENV['TEST_NO_DB'] == '1'
      skip "Skipping database test (TEST_NO_DB=1)"
    end
  end
end