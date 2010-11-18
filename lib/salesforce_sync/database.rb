gem 'activerecord', '= 3.0.3'
require 'active_record'

class SalesforceSync::Database

  include SalesforceSync

  DefaultOptions = { 
    :syncs_table => '_salesforce_syncs'
  }

  def initialize(options)
    @options = DefaultOptions.merge(options)
    ActiveRecord::Base.establish_connection(@options[:connection])
    create_syncs_table(@options[:syncs_table]) unless db.table_exists? @options[:syncs_table]
  end

  def sync_table(object, fields)
    if db.table_exists? object
      logger.info "updating table #{object.inspect}"

      db.change_table object do |t|
        columns = db.columns(object).index_by { |c| c.name }
        
        (columns.keys - fields.keys).each do |name|
          t.remove(name)
        end

        (fields.keys - columns.keys).each do |name|
          create_column(t, fields[name])
        end
        
      end
      
    else
      logger.info "creating table #{object.inspect}"
      
      db.create_table(object, :id => false) do |t|
        fields.each do |f|
          create_column(t, f)
        end
      end
      
      db.execute("ALTER TABLE %s ADD PRIMARY KEY (%s)" %
                 [db.quote_table_name(object), db.quote_column_name('Id')])
    end
  end

  def transaction(&block)
    ActiveRecord::Base.transaction(&block)
  end

  def last_sync
    db.select_value('SELECT started_at FROM %s ORDER BY id DESC LIMIT 1' % syncs_table)
  end

  def insert_sync_timestamp(timestamp)
    db.insert('INSERT INTO %s (started_at) VALUES (%s)' % [syncs_table, db.quote(timestamp)])
  end

  protected
  
  def syncs_table
    @syncs_table ||= db.quote_table_name(@options[:syncs_table])
  end

  def create_syncs_table(name)
    db.create_table(name) do |t|
      t.datetime :started_at
    end
  end

  def create_column(table, field)
    type, options = Salesforce::Types.to_sql(field)
    table.send(type, field[:name], options)
  end
  
  def db
    ActiveRecord::Base.connection
  end
    
end
