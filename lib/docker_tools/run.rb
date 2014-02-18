require "docker"

module DockerTools
  class Run
    attr_accessor :container

    def initialize(name, registry, tag, image = nil, command = nil, volumes = [])
      @name = name
      @registry = registry
      @tag = tag
      @command = command
      @volumes = volumes
      @image = "#{@registry}/#{@name}:#{@tag}" if image.nil?
      @image = image unless image.nil?
      @container = create_container(@image, @command, @volumes)
    end

    private
    def create_container(image, command, volumes)
      create_args = { 'Image' => image, 'Tty' => false }
      create_args['Cmd'] = command.strip.split(/\s+/) unless command.nil?
      create_args['Volumes'] = volumes_create if volumes.kind_of?(Array) and volumes.size > 0
      container = Docker::Container.create(create_args)
      container.start('Binds' => volumes)
      container
    end
    def volumes_create
      @volumes.each_with_object({}) { | volume, acc |  acc[volume.split(':').first] = {} }
    end
  end
end
