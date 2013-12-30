module DockerTools
  class Debootstrap
    attr_accessor :archive

    def initialize(name, distro, tmpdir='/tmp')
      @name = name
      @distro = distro
      @tmpdir = tmpdir
      @archive = "#{@tmpdir}/#{@name}.tar"
    end

    def run
      output = `debootstrap #{@distro} #{@tmpdir}/#{@name}`
      unless $?.to_i == 0
        puts output
        throw "Could not run debootstrap"
      end
      `cd #{@tmpdir}/#{@name} && tar -cvf ../#{@name}.tar .`
    end

    def cleanup
      `rm -rf #{@tmpdir}/#{@name}*`
    end
  end
end
