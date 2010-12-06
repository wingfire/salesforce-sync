module SalesforceSync::Synchronization

  extend SalesforceSync

  def self.run(options, salesforce, database)
    lock_file = File.new(options[:lock_file], 'w')

    unless lock_file.flock(File::LOCK_EX|File::LOCK_NB)
      logger.info 'another process is already running. exiting.'
      exit 2
    end

    if options[:clean]
      logger.info 'deleting _salesforce_syncs entries older than %i days' % options[:clean]
      database.clean_syncs_table(options[:clean])
    end
    
    logger.info 'starting schema synchronization'
    start = salesforce.current_time
    
    database.transaction do
      salesforce.schema.each do |object, fields|
        database.sync_table(object, fields)
      end
    end

    logger.info 'starting data synchronization'
    
    salesforce.schema.each do |object, fields|
      table = database.quote_table_name(object)
      last_sync = database.last_sync_for(object)

      if last_sync
        logger.info 'synchronizing all %s records modified since %s' % [object, last_sync]
      else
        logger.info 'synchronizing all %s records (initial)' % object
      end
      
      salesforce.modified_records_since(object, fields, last_sync, start) do |records, timestamp_field|
        database.transaction do
          records.each do |record|
            database.sync_record(table, type_cast_record(fields, record))
          end
          
          database.insert_sync_timestamp(object, records.last[timestamp_field.to_sym])
        end
      end

      database.insert_sync_timestamp(object, start)
    end

    lock_file.flock(File::LOCK_UN)
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
