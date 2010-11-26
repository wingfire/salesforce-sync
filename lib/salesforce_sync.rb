require 'logger'

module SalesforceSync

  mattr_accessor :logger

  def self.run(options)
    init_logger(options[:verbose], options[:debug])
    
    salesforce = Salesforce.new(options[:salesforce].symbolize_keys)
    database = Database.new(options[:database].symbolize_keys)

    if options[:interactive]
      Interactive.run(binding)
    else
      Synchronization.run(salesforce, database)
    end
  end

  def self.init_logger(verbose, debug)
    @@logger = Logger.new($stdout)
    logger.level = if debug
                     Logger::DEBUG
                   elsif verbose
                     Logger::INFO
                   else
                     Logger::ERROR
                   end
  end
  
end
