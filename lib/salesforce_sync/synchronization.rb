module SalesforceSync::Synchronization

  extend SalesforceSync

  def self.run(salesforce, database)
    database.transaction do
      logger.info 'starting schema synchronization'
      
      salesforce.schema.each do |object, fields|
        database.sync_table(object, fields)
      end

      logger.info 'starting data synchronization'
      last_sync = database.last_sync
      logger.info('last sync: %s' % (last_sync || 'none'))
      database.insert_sync_timestamp(salesforce.current_time)
    end
  end
  
end
