module FreshConnection
  module Extend
    module ArRelation
      module ForRails3
        def self.prepended(base)
          base.class_eval do
            undef :read_master!
          end
        end

        def pluck(column_name)
          if column_name.is_a?(Symbol) && column_names.include?(column_name.to_s)
            column_name = "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(column_name)}"
          end

          result = manage_access do
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
