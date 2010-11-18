module SalesforceSync::Synchronization

  extend SalesforceSync

  def self.run(salesforce, database)
    database.transaction do
      last_sync = database.last_sync
      database.insert_sync_timestamp(salesforce.current_time)
      
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
    end
  end
  
end
