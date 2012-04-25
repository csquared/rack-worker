require 'sequel'

module Rack
  class Worker
    class PostgresCache
      attr :db

      def initialize(db_url, table_name, expires_on = nil)
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
        @db[@table_name].insert(:key => key, :value => value, :expires_on => expires_on)
      end

      def get(key)
        (record = _get(key)) && (record[:value])
      end

      def delete(key)
        @db[@table_name].where(:key => key).delete
      end

      private 
      def _get(key)
        @db[@table_name].filter("expires_on > now() or expires_on IS NULL").first(:key => key)
      end

    end
  end
end
