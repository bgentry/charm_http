
class CharmHttp
  class Setup
    def self.start(n)
      instances = CharmHttp.instances

      if instances.size < n
        (n - instances.size).times do
          instance = C[:image].run_instance(C.slice(:key_pair, :security_groups, :instance_type))
          puts "Booted new instance"
          instances << instance
        end
        while instances.any? {|i| i.status != :running} do
          sleep 1
        end
      elsif instances.size > n
        instances[n..-1].each do |instance|
          puts "#{instance.public_dns_name} terminated"
          instance.delete
        end
        while instances.any? {|i| i.status == :stopping} do
          sleep 1
        end
      end

      instances.each do |instance|
        puts "#{instance.public_dns_name} running"
      end

      [
      "yes | sudo apt-get install make gcc git-core libevent-dev",
      "git clone https://github.com/archaelus/hummingbird.git || (cd hummingbird && git pull)",
      "cd hummingbird && make hstress"
      ].each do |command|
        CharmHttp.parallel_ssh(instances, command)
      end
    end

    def self.stop
      CharmHttp.instances.each do |instance|
        puts "#{instance.public_dns_name} terminated"
        instance.delete
      end

      begin
        C[:security_groups].delete
      rescue AWS::EC2::Errors::InvalidGroup::InUse
        sleep 2
        retry
      end
      C[:key_pair].delete
      File.unlink(C[:key_file])
    end
  end
end
