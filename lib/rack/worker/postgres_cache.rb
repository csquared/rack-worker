module Rack
  class Worker
    class PostgresCache
      def initialize(db_url, table_name, expires_on)
        @db = ::Sequel.connect db_url
        @table_name = table_name
        @expires_on = expires_on
        unless @db.table_exists? @table_name
          @db << "CREATE TABLE #{@table_name} (
            id serial, 
            key text,
            value text, 
            expires_on timestamptz
          )"
        end
      end

      def add(key, value, expires_on = nil)
        expires_on ||= @expires_on
        @db[@table_name].insert(:key => key, :value => value)
      end

      def get(key)
        (record = @db[@table_name].first(:key => key)) && (record[:value])
      end

      def delete(key)
        @db[@table_name].where(:key => key).delete
      end
    end
  end
end
