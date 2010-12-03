require 'rforce'
require 'active_support/core_ext/array/grouping'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/class/attribute'

class SalesforceSync::Salesforce

  class_attribute :blacklist
  self.blacklist = %w[NewsFeed EntitySubscription UserProfileFeed Vote] + # not allowed to query arbitrarily
    %w[GroupMember FiscalYearSettings QueueSobject UserLicense Period UserPreference] # lacking timestamps
  
  class_attribute :timestamp_fields
  self.timestamp_fields = %w[LastModifiedDate CreatedDate]

  include SalesforceSync

  def initialize(options)
    @options = options
    @connection = options[:connection].symbolize_keys
    @api_calls = 0
    self.blacklist += options[:blacklist]

    if logger.info?
      at_exit do
        logger.info 'used %d Salesforce API calls' % @api_calls
      end
    end
  end
  
  def schema
    schema_live
  end

  def schema_cache
    @schema ||= YAML.load_file('schema.yml')
  end

  def schema_live_with_caching
    @schema ||= File.open('schema.yml', 'w') do |f|
      f.write(schema_live.to_yaml)
      schema_live
    end
  end
  
  def schema_live
    @schema ||= object_names.in_groups_of(100, false).inject({ }) do |r, ss|
      call(:describeSObjects, ss).each do |sobject|
        if sobject[:queryable] != 'true'
          logger.debug('%s is not queryable, skipping' % sobject[:name])
        elsif blacklist.include?(sobject[:name])
          logger.debug('%s is blacklisted, skipping' % sobject[:name])
        else
          fields = sobject[:fields].is_a?(Array) ? sobject[:fields] : [sobject[:fields]]
          r[sobject[:name]] = fields.index_by { |f| f[:name] }
        end
      end
      
      r
    end
  end

  def object_names
    @object_names ||= call(:describeGlobal).sobjects.map { |s| s[:name] }
  end

  def current_time
    call(:getServerTimestamp).timestamp
  end

  def modified_records_since(object, fields, from, to, &block)
    timestamp_field = timestamp_fields.detect { |s| fields.has_key? s }
    raise "%s doesn't have a known timestamp field" % object unless timestamp_field
    
    query = 'SELECT %s FROM %s' % [fields.keys.join(', '), object]
    query << ' WHERE %s < %s' % [timestamp_field, to]
    query << ' AND %s >= %s' % [timestamp_field, from] if from
    
    result = call(:queryAll, query)

    as_array(result.records).each(&block) if result.records
    
    while result.done == 'false'
      logger.debug('querying more %s' % object)
      result = call(:queryMore, result.queryLocator)
      as_array(result.records).each(&block)
    end
  end

  protected

  def as_array(o)
    o.is_a?(Array) ? o : [o]
  end

  def call(method, arg = nil)
    args = case arg
           when Hash
             arg
           when Array
             arg.inject([]) { |a,v| a << :string << v }
           else
             { :arg => arg }
           end

    logger.debug("calling #{method} with #{args.inspect}")
    @api_calls += 1 if logger.info?
      
    result = rforce.send(method, args)
    
    if result[:Fault]
      raise result[:Fault].to_yaml.gsub('\\n', "\n")
    else
      result.send("#{method}Response").result
    end
  end

  def rforce
    @rforce ||= RForce::Binding.new(@connection[:url]).tap do |b|
      b.login(@connection[:username], "#{@connection[:password]}#{@connection[:token]}")
      b.batch_size = @options[:batch_size] || 2000
    end
  end
  
end
