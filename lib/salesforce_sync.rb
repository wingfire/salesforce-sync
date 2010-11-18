require 'active_support/buffered_logger'

module SalesforceSync

  mattr_accessor :logger

  def self.run(options)
    init_logger(options[:verbose])
    
    salesforce = Salesforce.new(options[:salesforce].symbolize_keys)
    database = Database.new(options[:database].symbolize_keys)

    if options[:interactive]
      Interactive.run(binding)
    else
      Synchronization.run(salesforce, database)
    end
  end

  def self.init_logger(verbose)
    @@logger = ActiveSupport::BufferedLogger.new($stdout)
    logger.level = verbose ? ActiveSupport::BufferedLogger::DEBUG : ActiveSupport::BufferedLogger::INFO
  end
  
end
