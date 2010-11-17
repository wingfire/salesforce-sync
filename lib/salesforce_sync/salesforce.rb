gem 'rforce', '= 0.4.1'
require 'rforce'
require 'active_support/core_ext/array/grouping'

class SalesforceSync::Salesforce

  def initialize(options)
    @options = options
  end

  def schema_cache
    @schema ||= YAML.load_file('schema.yml')
  end
  
  def schema
    @schema ||= object_names.in_groups_of(100, false).inject({ }) do |r, ss|
      binding.describeSObjects(typed_array(:string, ss))[:describeSObjectsResponse][:result].each do |sobject|
        r[sobject[:name]] = sobject[:fields]
      end

      r
    end
  end

  def object_names
    @object_names ||= binding.describeGlobal({ })[:describeGlobalResponse][:result][:sobjects].map { |s| s[:name] }    
  end

  protected
  
  def binding
    @binding ||= RForce::Binding.new(@options[:url]).tap do |b|
                   b.login(@options[:username], "#{@options[:password]}#{@options[:token]}")
                   b.batch_size = @options[:batch_size] || 2000
                 end
  end

  def typed_array(type, args)
    args.inject([]) { |a,v| a << type << v }
  end
  
end
