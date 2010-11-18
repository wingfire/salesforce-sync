require 'irb'

module SalesforceSync::Interactive
  
  ::IRB.extend(self)
  
  def start_session(binding)
    unless @__initialized
      args = ARGV
      ARGV.replace(ARGV.dup)
      IRB.setup(nil)
      ARGV.replace(args)
      @__initialized = true
    end
    
    workspace = ::IRB::WorkSpace.new(binding)
    
    irb = ::IRB::Irb.new(workspace)
    
    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context
    
    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end
  
  def self.run(binding)
    IRB.start_session(binding)
  end
  
end
