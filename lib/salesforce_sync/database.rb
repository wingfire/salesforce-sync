gem 'activerecord', '= 3.0.3'
require 'active_record'

class SalesforceSync::Database

  include SalesforceSync

  def initialize(options)
    ActiveRecord::Base.establish_connection(options)
    @connection = ActiveRecord::Base.connection
  end

  def sync_table(object, fields)
    logger.info "creating #{object}"
    
    @connection.create_table(object, :id => false) do |t|
      fields.each do |f|
        type = salesforce_to_sql_type(f[:type])
        t.send(type, f[:name], sql_type_options(type, f))
      end

      t.primary_key 'Id'
    end
  end

  def transaction(&block)
    ActiveRecord::Base.transaction(&block)
  end

  protected
  
  def salesforce_to_sql_type(type)
    case type.downcase
    when 'id', 'base64', 'combobox', 'byte', 'string', 'anytype', 'combobox', 'email', 'encryptedstring', 'masterrecord', 'multipicklist', 'phone', 'picklist', 'reference', 'textarea', 'url'
      :text
    when 'boolean'
      :boolean
    when 'double', 'currency', 'percent'
      :decimal
    when 'int'
      :integer
    when 'date'
      :date
    when 'datetime'
      :datetime
    when 'time'
      :time
    else
      $stderr.puts("unknown type: #{type.inspect}, falling back to text")
      :text
    end
  end

  def sql_type_options(type, field)
    case type
    when :double
      { :scale => field[:scale].to_i, :precision => field[:precision].to_i }
    else
      { }
    end
  end
    
end
