require 'active_support/deprecation'

module FreshConnection
  module Extend
    module ArRelation
      def self.prepended(base)
        case ActiveRecord::VERSION::MAJOR
        when 4
          base.__send__(:prepend, ForRails4)
        when 3
          base.__send__(:prepend, ForRails3)
        end
      end

      def calculate(operation, column_name, options = {})
        if options[:readonly] == false
          ActiveSupport::Deprecation.warn(":readonly key has been deprecated.", caller)
        end

        slave_access = enable_slave_access && options[:readonly] != false
        @klass.manage_access(slave_access) { super }
      end

      def enable_slave_access
        connection.open_transactions == 0 && @read_from_master.nil?
      end

      def readonly(value = true)
        if value == false
          ActiveSupport::Deprecation.warn("readonly(false) has been deprecated. Use read_master instead", caller)
          read_master
        else
          super
        end
      end

      private

      def exec_queries
        return @records if loaded?

        @klass.manage_access(enable_slave_access) do
          super
        end
      end

      module ForRails4
        def pluck(*args)
          @klass.manage_access(enable_slave_access) { super }
        end

        def read_master
          spawn.read_master!
        end

        def read_master!
          @read_from_master = true
          self
        end
      end

      module ForRails3
        def pluck(column_name)
          if column_name.is_a?(Symbol) && column_names.include?(column_name.to_s)
            column_name = "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(column_name)}"
          end

          result = @klass.manage_access(enable_slave_access) do
            klass.connection.select_all(select(column_name).arel, nil)
          end

          return result if result.nil? || result.empty?

          last_columns = result.last.keys.last

          result.map do |attributes|
            klass.type_cast_attribute(last_columns, klass.initialize_attributes(attributes))
          end
        end

        def read_master
          relation = clone
          relation.instance_variable_set("@read_from_master", true)
          relation
        end
      end
    end
  end
end
