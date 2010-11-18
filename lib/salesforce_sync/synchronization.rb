module SalesforceSync::Synchronization

  def self.run(salesforce, database)
    database.transaction do
      salesforce.schema.each do |object, fields|
        database.sync_table(object, fields)
      end
    end
  end
  
end
