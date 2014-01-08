require "docker"

module DockerTools
  class Run
    attr_accessor :container

    def initialize(name, registry, tag, command = nil, volumes = [])
      @name = name
      @registry = registry
      @tag = tag
      @command = command
      @volumes = volumes
      @container = create_container
    end

    private
    def create_container
      create_args = { 'Image' => "#{@registry}/#{@name}:#{@tag}", 'Tty' => true }
      create_args['Cmd'] = [@command] unless @command.nil?
      create_arfs['Volumes'] = volumes_create if @volumes.kind_of?(Array) and @volumes.size > 0
      container = Docker::Container.create(create_args)
      container.start('Binds' => @volumes)
      container
    end
    def volumes_create
      @volumes.each_with_object({}) { | volume, acc |  acc[volume.split(':').first] = {} }
    end
  end
end
