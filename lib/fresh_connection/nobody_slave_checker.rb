module FreshConnection
  class NobodySlaveChecker
    def down?(message)
      false
    end
  end
end
