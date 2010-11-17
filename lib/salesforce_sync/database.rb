gem 'activerecord', '= 3.0.3'
require 'active_record'

class SalesforceSync::Database

  include SalesforceSync

  def initialize(options)
    ActiveRecord::Base.establish_connection(options)
  end

  def sync_table(object, fields)
    logger.info "creating #{object}"
    
    db.create_table(object, :id => false) do |t|
      fields.each do |f|
        type, options = Salesforce::Types.to_sql(f)
        t.send(type, f[:name], options)
      end
    end
    
    db.execute("ALTER TABLE %s ADD PRIMARY KEY (%s)" %
                [db.quote_table_name(object), db.quote_column_name('Id')])
  end

  def transaction(&block)
    ActiveRecord::Base.transaction(&block)
  end

  protected
  
  def db
    ActiveRecord::Base.connection
  end
    
end
