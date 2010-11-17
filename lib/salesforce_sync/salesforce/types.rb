module SalesforceSync::Salesforce::Types

  def self.to_sql(field)
    type = sql_type(field[:type].downcase)
    return type, sql_options(type, field)
  end

  def self.sql_type(type)
    case type
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
  
  def self.sql_options(type, field)
    case type
    when :double
      { :scale => field[:scale].to_i, :precision => field[:precision].to_i }
    else
      { }
    end
  end
  
end
