gem 'activerecord', '= 3.0.3'
require 'active_record'

class SalesforceSync::Database

  include SalesforceSync

  def initialize(options)
    ActiveRecord::Base.establish_connection(options)
    @connection = ActiveRecord::Base.connection
  end

  def sync_table(object, fields)
    logger.info "creating #{object}"
    
    @connection.create_table(object, :id => false) do |t|
      fields.each do |f|
        type, options = Salesforce::Types.to_sql(f)
        t.send(type, f[:name], options)
      end

      t.primary_key 'Id'
    end
  end

  def transaction(&block)
    ActiveRecord::Base.transaction(&block)
  end
    
end
