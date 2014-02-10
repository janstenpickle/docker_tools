require "docker"
require "json"
require "erubis"
require "docker_tools"

module DockerTools
  class Image
    attr_accessor :name, :registry, :tag, :dir, :full_name, :image


    def initialize(name, registry, tag, dir=nil, lookup=true)
      @name = name
      @registry = registry
      @tag = tag
      @full_name = "#{registry}/#{name}:#{tag}" unless registry.nil?
      @full_name = "#{name}:#{tag}" if registry.nil?
      @image_name = "#{registry}/#{name}" unless registry.nil?
      @image_name = name if registry.nil?
      @dir = dir
      @dockerfile = "#{dir}/Dockerfile.template" unless dir.nil?
      @image = lookup_image if lookup
      # Set the read timeout for the connection
      Excon.defaults[:read_timeout] = DockerTools.image_timeout
    end

    def pull
      puts "Pulling image #{@image_name}"
      Docker::Image.create('fromImage' => @image_name, 'tag' => @tag)
      @image = lookup_image
    end

    def build(registry: @registry, tag: @tag, method: 'image', distro: 'precise', fallback_tag: DockerTools.dependency_fallback_tag, no_pull: DockerTools.no_pull, template_vars: {}, rm: false, no_cache: false)
      case method
      when 'image'
        dependency_tag = dependency['tag']
        dependency_tag = DockerTools::Dependency.new(dependency['repository'], dependency['registry'], dependency['tag'], fallback_tag).run unless no_pull

        dockerfile_path = "#{@dir}/Dockerfile"
        dockerfile_contents = dockerfile(@name, registry, dependency_tag, template_vars)
        File.open(dockerfile_path, 'w') { | file | file.write(dockerfile_contents) }
        @image = Docker::Image.build_from_dir(@dir, { 'rm' => rm, 'nocache' => no_cache }) do | chunk | 
          Docker::Util.parse_output(chunk) do | output |
            if output.kind_of?(Hash)
              if output.has_key?('error')
                puts output['error']
                raise output['error']
              end
              puts output['stream'] if output.has_key?('stream')
            else
              puts output
            end
          end
        end
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
      @image
    end

    def tag (new_tag)
      @image.tag('repo' => "#{@registry}/#{@name}", 'tag' => new_tag, 'force' => true) if image_present?
    end

    def dependency
      if @dockerfile.nil?
        return nil
      else
        template = dockerfile
        dependency = {}
        if template =~ /(FROM|from)\s+(\S+)\/(\S+):(\S+)/
          dependency['registry'] = $2
          dependency['repository'] = $3
          dependency['tag'] = $4
          return dependency
        elsif template =~ /(FROM|from)\s+(\S+):(\S+)/
          dependency['registry'] = nil
          dependency['repository'] = $2
          dependency['tag'] = $3
        elsif template =~ /(FROM|from)\s+(\S+)$/
          dependency['registry'] = nil
          dependency['repository'] = $2
          dependency['tag'] = nil
        end
        dependency
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
        if image.info['RepoTags'].include?(@full_name)
          return image
        end
      end
      nil
    end
  end
end
