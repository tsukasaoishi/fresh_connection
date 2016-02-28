module FreshConnection
  module Extend
    module ArRelation
      module ForRails
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
    end
  end
end
