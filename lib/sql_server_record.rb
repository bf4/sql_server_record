require "sql_server_record/version"
require "sql_server_record/base"

module SqlServerRecord
  def self.root
    Rails.root
  end

  def self.logger
    Rails.logger
  end
end
