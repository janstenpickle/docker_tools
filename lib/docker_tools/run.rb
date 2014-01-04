require "docker"

module DockerTools
  class Run
    attr_accessor :container

    def initialize(name, registry, tag, command=nil)
      @name = name
      @registry = registry
      @tag = tag
      @command = command
      @container = create_container
    end

    private
    def create_container
      container = Docker::Container.create('Cmd' => [@command], 'Image' => "#{@registry}/#{@name}:#{@tag}")
      container.start
      container
    end
  end
end
