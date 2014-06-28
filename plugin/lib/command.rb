
module Stratos

  RUBY = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name']).sub(/.*\s.*/m, '"\&"')

  class Command < Vagrant.plugin("2", "command")
    def execute

      opts = OptionParser.new do |o|
        o.banner = "Usage: vagrant script scriptname.rb"
      end
      argv = parse_options(opts)

      puts argv

      IO.popen "vagrant ssh -c './stratos.sh -m'" do |io|
        io.each do |line|
          puts line.tr("\n","")
        end
      end

      return 0
    end
  end
end
