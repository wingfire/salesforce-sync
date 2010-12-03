module SalesforceSync::Synchronization

  extend SalesforceSync

  def self.run(salesforce, database)
    logger.info 'starting schema synchronization'
    start = salesforce.current_time
    
    database.transaction do
      salesforce.schema.each do |object, fields|
        database.sync_table(object, fields)
      end
    end

    logger.info 'starting data synchronization'
    
    salesforce.schema.each do |object, fields|
      database.transaction do 
        table = database.quote_table_name(object)
        last_sync = database.start_new_sync_for(object, start)

        if last_sync
          logger.info 'synchronizing all %s records modified since %s' % [object, last_sync]
        else
          logger.info 'synchronizing all %s records (initial)' % object
        end
        
        salesforce.modified_records_since(object, fields, last_sync, start) do |record|
          database.sync_record(table, type_cast_record(fields, record))
        end
      end
    end
  end

  protected

  def self.type_cast_record(fields, record)
    casted = { }
    
    record.each do |k, v|
      casted[k.to_s] = ::SalesforceSync::Salesforce::Types.cast_value(fields[k.to_s], v) unless k == :type
    end

    casted
  end
  
end
