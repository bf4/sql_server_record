# Usage:
#
# class MySqlServerRecord < SqlServerRecord::Base
#   # Prevent ActiveRecord from querying the database for column information
#   self.abstract_class = true
#   establish_sql_server_connection Rails.application.config_for(:my_sql_server)
#   self.pluralize_table_names = false
# end
# class SomeTable < MySqlServerRecord
# end
#
# and in config/initializers/my_sql_server_record.rb
#
# ActiveSupport.on_load(:active_record) do
#   MySqlServerRecord.table_name_prefix = 'dbo.'
#   adapter = ActiveRecord::ConnectionAdapters::SQLServerAdapter
#   adapter.lowercase_schema_reflection = true
# end
module SqlServerRecord
  class Base < ActiveRecord::Base
    class_attribute :sql_server_connection_config, instance_writer: false

    # Prevent ActiveRecord from querying the database for column information
    self.abstract_class = true

    # @example config/sql_server.yml
    #   {
    #     "adapter"=>"sqlserver",
    #     "mode"=>"dblib",
    #     "host"=>"localhost",
    #     "port"=>1433,
    #     "database"=>"myapp_development",
    #     "username"=>"rails",
    #     "password"=>nil,
    #     "collation"=>nil,
    #     "encoding"=>"utf8"
    #   }
    #   Is passed to +TinyTds::Client.new+ as
    #   client = TinyTds::Client.new(
    #     "host"=>"localhost",
    #     "port"=>1433,
    #     "database"=>"myapp_development",
    #     "username"=>"rails",
    #     "password"=>nil,
    #     "encoding"=>"utf8"
    #     "dataserver"=>nil,
    #     "tds_version"=>"7.3",
    #     "appname"=>"MyApp",
    #     "login_timeout"=>nil,
    #     "timeout"=>nil,
    #     "azure"=>nil,
    #     "contained"=>nil
    #   )
    def self.establish_sql_server_connection(config)
      self.sql_server_connection_config = config
      establish_connection(config)
    end
  end
end
