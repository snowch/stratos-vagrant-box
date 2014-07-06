class StratosPluginException < Vagrant::Errors::VagrantError
   # FIXME cmd_string is not populated
   error_message("[vagrant stratos] There was a problem running the command: %{cmd_string}")
end

module Stratos

  require_relative 'command_util'

  RUBY = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name']).sub(/.*\s.*/m, '"\&"')

  class Command < Vagrant.plugin("2", "command")

    def execute
      options = {}
      opts = OptionParser.new do |o|
        o.banner = "Usage: vagrant stratos [--help] [-a|--all] [-c|--create] [-w|--desktop] [-o|--openstack] [-d|--destroy]"

        o.on("-a", "--all", "Equivalent to running: 'vagrant stratos --create --desktop --openstack --destroy'") do |v|
          options[:newenv] = true
          options[:desktop] = true
          options[:destroy] = true
        end
        o.on("-c", "--create", "Create a new Stratos environment") do |v|
          options[:newenv] = v
        end
        o.on("-w", "--desktop", "Add Desktop to Stratos Environment") do |v|
          options[:desktop] = v
        end
        o.on("-o", "--openstack", "Install Openstack (devstack) environment") do |v|
          options[:openstack] = v
        end
        o.on("-d", "--destroy", "Destroy previous Stratos environment") do |v|
          options[:destroy] = v
        end
      end
      argv = parse_options(opts)

      # TODO print vagrant configuration such as stratos branch

      if argv.nil?
         # help gets printed by vagrant code
         # this gets appended under the help:
         puts "
 Additional Information
 ======================

 - Access Stratos Console: https://192.168.56.5:9443/console - admin/admin
 - Access Openstack Console: http://192.168.92.30 - admin/g
 - You can ssh into your environment using 'vagrant ssh'
 - If you created a development environment, you can access it using rdesktop or Windows Remote Desktop
    - IP: 192.168.56.5
    - Username: vagrant
    - Password: vagrant
 - See stratos.log for Stratos and Openstack setup output
 - See test.log for basic provisioning output TODO #{Dir.pwd}
" 
         return 0
      end

      if options.empty?
         puts "Execute 'vagrant stratos --help' to print usage instructions"
         return 0
      end

      if options[:destroy]
         run_command "vagrant destroy -f" # TODO is there a vagrant API for this?
      end
      run_command "vagrant up"         # Vagrant API?

      run_command "vagrant ssh -c './stratos.sh -m'" 
      run_command "vagrant ssh -c './stratos.sh -w'" 
      run_command "vagrant ssh -c './stratos.sh -c'" 
      run_command "vagrant ssh -c './stratos.sh -b'" 
      run_command "vagrant ssh -c './stratos.sh -p'" 
      run_command "vagrant ssh -c './stratos.sh -n'" 
  
      if options[:desktop]
         run_command "vagrant ssh -c './stratos.sh -d'" 
         run_command "vagrant reload"     # Vagrant API?
      end

      if options[:openstack]
         run_command "vagrant ssh -c './openstack-docker.sh -o'" 
         run_command "vagrant reload"     # Vagrant API?

         run_command "vagrant ssh -c './openstack-docker.sh -o && ./openstack-docker.sh -d'"
         run_command "vagrant ssh -c '. /vagrant/tests/test_stratos.sh'"
      end

      return 0
    end

    def run_command (cmd)
       begin
          StratosUtil.run_command cmd
       rescue RuntimeError => e
          raise StratosPluginException, cmd_string: cmd
       end
    end

  end # class

end # module

