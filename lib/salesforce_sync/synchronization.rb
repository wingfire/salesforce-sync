module SalesforceSync::Synchronization

  extend SalesforceSync

  def self.run(salesforce, database)
    database.transaction do
      last_sync = database.last_sync
      now = salesforce.current_time
      database.insert_sync_timestamp(now)
      
      if last_sync
        logger.info 'last synchronization: %s' % last_sync
      else
        logger.info 'initial synchronization'
      end
      
      logger.info 'starting schema synchronization'
      
      salesforce.schema.each do |object, fields|
        database.sync_table(object, fields)
      end

      logger.info 'starting data synchronization'

      salesforce.schema.each do |object, fields|
        table = database.quote_table_name(object)
        
        salesforce.modified_records_since(object, fields, last_sync, now) do |records|
          records.each do |record|
            database.sync_record(table, type_cast_record(fields, record))
          end
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
