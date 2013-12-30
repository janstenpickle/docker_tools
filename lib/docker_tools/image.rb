require "docker"
require "erubis"
require "docker_tools/debootstrap"


module DockerTools
  class Image
    def initialize(name, registry, tag, dockerfile=nil)
      @name = name
      @registry = registry
      @tag = tag
      @dockerfile = dockerfile
      @image = lookup_image
    end

    def pull
      @image = Docker::Image.create('fromImage' => "#{@registry}/#{@name}:#{@tag}" )
    end

    def build(registry: @registry, tag: @tag, method: 'image', distro: 'precise')
      case method
      when 'image'
        @image = Docker::Image.build(dockerfile(registry, tag))
      when 'debootstrap'
        debootstrap = DockerTools::Debootstrap.new(@name, distro)
        debootstrap.run
        @image = Docker::Image.import(debootstrap.archive)
        debootstrap.cleanup
      else
        raise "Invalid value for method: #{method}"
      end
      @image.tag('repo' => "#{@registry}/#{@name}", 'tag' => @tag, 'force' => true)
    end

    def tag (new_tag)
      @image.tag('repo' => "#{@registry}/#{@name}", 'tag' => new_tag, 'force' => true)
    end

    private
    def dockerfile(registry, tag)
      raise "Must specify Dockerfile location in image" if @dockerfile.nil?
      template = File.read(@dockerfile)
      template = Erubis::Eruby.new(template)
      template.result(:registry => registry, :tag => tag)
    end

    def lookup_image
      images = Docker::Image.all
      images.each do | image |
        if image.info['Repository'] == "#{@registry}/#{@name}" and image.info['Tag'] == @tag
          image
        end
      end
    end
  end
end
