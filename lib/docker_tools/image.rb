require "docker"
require "erubis"
require "docker_tools"

module DockerTools
  class Image
    attr_accessor :name, :registry, :tag, :dir, :full_name, :image

    def initialize(name, registry, tag, dir=nil, lookup=true)
      @name = name
      @registry = registry
      @tag = tag
      @full_name = "#{registry}/#{name}:#{tag}"
      @dir = dir
      @dockerfile = "#{dir}/Dockerfile.template" unless dir.nil?
      @image = lookup_image if lookup
    end

    def pull
      Docker::Image.create('fromImage' => "#{@registry}/#{@name}", 'tag' => @tag)
      @image = lookup_image
    end

    def build(registry: @registry, tag: @tag, method: 'image', distro: 'precise', fallback_tag: DockerTools.dependency_fallback_tag, no_pull: false, template_vars: {})
      case method
      when 'image'
        dependency_tag = dependency['tag']
        dependency_tag = DockerTools::Dependency.new(dependency['repository'], dependency['registry'], dependency['tag'], fallback_tag).run unless no_pull

        dockerfile_path = "#{@dir}/DockerFile"
        dockerfile_contents = dockerfile(@name, registry, dependency_tag, template_vars)
        File.open(dockerfile_path, 'w') { | file | file.write(dockerfile_contents) }
        @image = Docker::Image.build_from_dir(@dir)
        File.delete(dockerfile_path)

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
      @image.tag('repo' => "#{@registry}/#{@name}", 'tag' => new_tag, 'force' => true) if image_present?
    end

    def dependency
      if @dockerfile.nil?
        return nil
      else
        template = dockerfile
        if template =~ /(FROM|from)\s+(\S+)\/(\S+):(\S+)/
          dependency = {}
          dependency['registry'] = $2
          dependency['repository'] = $3
          dependency['tag'] = $4
          return dependency
        end
      end
    end

    private
    def image_present?
      throw "Image #{@full_name} is not present on the local machine" if @image.nil?
      return true
    end

    def dockerfile(name = @name, registry = @registry, tag = @tag, args = {})
      raise "Must specify Dockerfile location in image" if @dockerfile.nil?
      template = Erubis::Eruby.new(File.read(@dockerfile))
      template_vars = { :registry => registry, :tag => tag, :name => name }
      template_vars.merge!(args) if args.kind_of?(Hash)
      template.result(template_vars)
    end

    def lookup_image
      images = Docker::Image.all
      images.each do | image |
        if image.info['Repository'] == "#{@registry}/#{@name}" and image.info['Tag'] == @tag
          return image
        end
      end
      return nil
    end
  end
end
