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
#   adapter = ActiveRecord::ConnectionAdapters::SQLServerAdapter
#   adapter.lowercase_schema_reflection = true

#   MySqlServerRecord.table_name_prefix = 'dbo.'
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
      establish_connection(config.except(:database, "database"))
      at_exit { connection.close if connected? && connection.active? }
    end

    def self.inherited(klass)
      if klass.connected? && klass.sql_server_connection_config
        klass.use_database
      end
      super
    end

    def self.setup_database
      create_database
      use_database
      load_structure
    end

    def self.setup_database!
      drop_database
      setup_database
    end

    def self.database_name
      sql_server_connection_config.fetch("database")
    end

    def self.create_database
      connection.create_database(database_name)
    end

    def self.drop_database
      connection.reconnect!
      connection.drop_database(database_name)
    rescue ActiveRecord::NoDatabaseError
      nil # no-op
    end

    def self.use_database
      connection.use_database(database_name)
    end

    def self.load_structure(*files)
      STDERR.puts "No structure files given" if files.empty?
      files.map {|relative_path|
        load_script(relative_path, stmt_delimiter: :go)
      }
    end

    def self.load_data(*files)
      STDERR.puts "No data files given" if files.empty?
      files.map { |relative_path|
        load_script(relative_path, stmt_delimiter: :line_break)
      }
    end

    # @example reader argument
    #   reader = Zlib::GzipReader.new(file_handle)
    #   MySqlServerRecord.load_data(reader)
    #   MySqlServerRecord.load_script(reader, stmt_delimiter: :go)
    #
    # @param stmt_delimiter [Symbol] one of :line_break, :go
    def self.load_script(reader_or_relative_path, stmt_delimiter:)
      reader =
        if reader_or_relative_path.respond_to?(:read)
          reader_or_relative_path
        else
          pathname = SqlServerRecord.root.join(reader_or_relative_path)
          return unless pathname.exist?
          pathname
        end
      enumerator =
        case stmt_delimiter
        when :line_break then reader.readlines
        when :go
          string = reader.read
          scanner = StringScanner.new(string)
          Enumerator.new do |y|
            while !scanner.eos? && (stmt = scanner.scan_until(/^GO$/))
              y.yield stmt
            end
          end
        end
      track_queries do
        enumerator.each do |stmt|
          stmt = stmt.remove(-"\nGO").gsub(/^print.*$/, "").strip
          next if stmt.start_with?(-"/") || stmt.start_with?(-"USE") || stmt.start_with?(-"GO") || stmt.empty?
          result = connection.execute(stmt)
          # NOTE(BF): Uncomment the below to debug
          # print "#{result.inspect} "
        end
      end
      nil
    rescue => e
      SqlServerRecord.logger.info "Failed to execute query. exception='#{e.class}' message=#{e.message}' query='#{last_query.inspect}'"
    end

    def self.track_queries
      ActiveSupport::Notifications.unsubscribe("sql.active_record") # unsubscribe any existing subscriptions
      @last_query = nil
      defined?(@subscriber) && ActiveSupport::Notifications.unsubscribe(@subscriber)
      @subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, details|
        sql = details[:sql]
        @last_query = sql
      end
      yield
    ensure
      ActiveSupport::Notifications.unsubscribe(@subscriber)
    end

    def self.last_query
      @last_query
    end
  end
end
