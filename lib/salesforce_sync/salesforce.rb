gem 'rforce', '= 0.4.1'
require 'rforce'
require 'active_support/core_ext/array/grouping'
require 'active_support/core_ext/enumerable'

class SalesforceSync::Salesforce

  include SalesforceSync

  def initialize(options)
    @options = options
  end

  def schema_cache
    @schema ||= YAML.load_file('schema.yml')
  end
  
  def schema
    @schema ||= object_names.in_groups_of(100, false).inject({ }) do |r, ss|
      call(:describeSObjects, ss).each do |sobject|
        if sobject[:queryable] == 'true'
          fields = sobject[:fields].is_a?(Array) ? sobject[:fields] : [sobject[:fields]]
          r[sobject[:name]] = fields.index_by { |f| f[:name] }
        else
          logger.debug('%s is not queryable' % sobject[:name])
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
    timestamp_field = ['LastModifiedDate', 'CreatedDate'].detect { |s| fields.has_key? s }
    
    query = 'SELECT %s FROM %s' % [fields.keys.join(', '), object]
    query << ' WHERE %s < %s' % [timestamp_field, to]
    query << ' AND %s > %s' % [timestamp_field, from] if from

    result = call(:queryAll, query)

    yield(as_array(result.records)) if result.records
    
    while result.done == 'false'
      logger.debug('querying more %s' % object)
      result = call(:queryMore, result.queryLocator)
      yield(as_array(result.records))
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
    
    result = rforce.send(method, args)
    
    if result[:Fault]
      raise result[:Fault].to_yaml.gsub('\\n', "\n")
    else
      result.send("#{method}Response").result
    end
  end

  def rforce
    @rforce ||= RForce::Binding.new(@options[:url]).tap do |b|
      b.login(@options[:username], "#{@options[:password]}#{@options[:token]}")
      b.batch_size = @options[:batch_size] || 2000
    end
  end
  
end
