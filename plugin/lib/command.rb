
module Stratos

  RUBY = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name']).sub(/.*\s.*/m, '"\&"')

  class Command < Vagrant.plugin("2", "command")

    def execute
      opts = OptionParser.new do |o|
        o.banner = "Usage: vagrant script scriptname.rb"
      end
      argv = parse_options(opts)

      # TODO error handling and retries
      # TODO print vagrant configuration such as stratos branch

      run_command "vagrant destroy -f" # TODO is there a vagrant API for this?
      run_command "vagrant up"         # Vagrant API?

      run_command "vagrant ssh -c './stratos.sh -f'" 

      # TODO provide a vagrant command line option for setting up the desktop 
      # run_command "vagrant ssh -c './stratos.sh -d'" 
      run_command "vagrant ssh -c './openstack-docker.sh -o'" 
      run_command "vagrant reload"     # Vagrant API?

      run_command "vagrant ssh -c './openstack-docker.sh -o && ./openstack-docker.sh -d'"

      #sleep (5*60) # 5 mins
      run_command "vagrant ssh -c '. /vagrant/tests/test_stratos.sh'"

      return 0
    end

    def run_command( command )
       attempts = 0
       while attempts < 3 do
          attempts = attempts + 1
          IO.popen command do |io|
             io.each do |line|
                puts line.tr("\n","")
             end
             io.close
             if $?.to_i == 0 
                return
             else
                puts "[vagrant status] received an error running: #{command}"
                puts "[vagrant status] retrying command #{command}"
             end
          end 
       end
       abort "[vagrant status] aborting after #{attempts} failed attempts" 
     end # def run_command

  end # class

end # module
