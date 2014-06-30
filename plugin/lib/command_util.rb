
module StratosUtil

    def self.run_command( command )
       success = false
       attempts = 0
       while (!success and attempts < 3) do
          attempts = attempts + 1
          IO.popen command do |io|
             io.each do |line|
                puts line.tr("\n","")
             end
             io.close
             if $?.to_i == 0 
                success = true
                puts "[vagrant stratos] successfully ran command: #{command}"
             else
                puts "[vagrant stratos] received an error running: #{command}"
                puts "[vagrant stratos] retrying command #{command}"
             end
          end 
       end
       if !success
          raise "[vagrant stratos] aborting after #{attempts} failed attempts" 
       end
     end # def run_command

end # module
