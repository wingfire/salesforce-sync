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
      db.change_table object do |table|
        columns = db.columns(object).index_by { |c| c.name }
        
        (columns.keys - fields.keys).each do |name|
          logger.info "removing #{name} from #{object}"
          table.remove(name)
        end

        (fields.keys - columns.keys).each do |name|
          logger.info "adding #{name} to #{object}"
          create_column(table, fields[name])
        end
      end
    else
      logger.info "creating table #{object.inspect}"
      
      db.create_table(object, :id => false) do |table|
        fields.each do |name, field|
          create_column(table, field)
        end
      end
      
      db.execute("ALTER TABLE %s ADD PRIMARY KEY (%s)" %
                 [db.quote_table_name(object), db.quote_column_name('Id')])
    end
  end

  def sync_record(table, record)
    if db.select_value('SELECT "Id" FROM %s WHERE "Id" = %s' % [table, db.quote(record['Id'])])
      logger.info('updating %s' % record['Id'])
      db.update('UPDATE %s SET %s WHERE "Id" = %s' % [table, values_for_update(record), db.quote(record['Id'])])
    else
      logger.info('inserting %s' % record['Id'])
      db.insert('INSERT INTO %s %s' % [table, values_for_insert(record)])
    end
  end

  def transaction(&block)
    ActiveRecord::Base.transaction(&block)
  end

  def last_sync_for(object)
    db.select_value('SELECT timestamp FROM %s WHERE object = %s ORDER BY created_at DESC LIMIT 1' %
                    [syncs_table, db.quote(object)])
  end

  def insert_sync_timestamp(object, timestamp)
    db.insert("INSERT INTO %s (object, timestamp, created_at) VALUES (%s, %s, statement_timestamp() AT TIME ZONE 'UTC')" %
              [syncs_table, db.quote(object), db.quote(timestamp)])
  end

  def clean_syncs_table(days)
    db.delete("DELETE FROM %s AS a WHERE created_at < (SELECT MAX(created_at) FROM %s WHERE object = a.object) AND created_at < statement_timestamp() AT TIME ZONE 'UTC' - interval '%i days'" % 
              [syncs_table, syncs_table, db.quote(days)])
  end

  def quote_table_name(name)
    db.quote_table_name(name)
  end
  
  protected

  def values_for_update(record)
    record.except('Id').map do |k, v|
      '%s = %s' % [db.quote_column_name(k), db.quote(v)]
    end.join(', ')
  end

  def values_for_insert(record)
    '(' + record.inject([[], []]) do |r, (k, v)|
      r[0] << db.quote_column_name(k)
      r[1] << db.quote(v)
      r
    end.map do |l|
      l.join(', ')
    end.join(') VALUES (') + ')'
  end
  
  def syncs_table
    @syncs_table ||= db.quote_table_name(@options[:syncs_table])
  end

  def create_syncs_table(name)
    db.create_table(name) do |t|
      t.text :object
      t.text :timestamp
      t.integer :created_at
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
