require 'active_support/core_ext/hash/slice'

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
      "sudo apt-get update",
      "yes | sudo apt-get install git-core mercurial",
      "which go || (curl -o goinst.sh https://gist.githubusercontent.com/bgentry/3f508a2c6cb6417ad46c/raw/d3f065b9d5da740045634ef0a4dea98425528f7d/goinst.sh && chmod +x goinst.sh && sudo VERSION=1.3.1 ./goinst.sh)",
      "source /etc/profile && go get -u github.com/bgentry/vegeta && cd $GOPATH/src/github.com/bgentry/vegeta && git checkout buckets && go install",
      "source /etc/profile && sudo cp `which vegeta` /usr/local/bin/",
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
