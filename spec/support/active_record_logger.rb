require 'logger'

ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), '../../log/sql.log'))
