require "docker"
require "erubis"
require "docker_tools/image"


module DockerTools
  attr_accessor :name

  class Dependency
    def initialize(name, registry, tag, fallback_tag)
      @name = name
      @registry = registry
      @tag = tag
      @fallback_tag = fallback_tag
    end

    def run
      tag = @tag
      image = DockerTools::Image.new(@name, @registry, @tag)
      begin
        image.pull
        throw "Cannot find image" if image.image.nil?
      rescue
        puts "Falling back to image #{@registry}/#{@name}:#{@fallback_tag}"
        image = DockerTools::Image.new(@name, @registry, @fallback_tag)
        image.pull
        throw "Cannot find image" if image.image.nil?
        tag = @fallback_tag
      end
      tag
    end

  end
end
