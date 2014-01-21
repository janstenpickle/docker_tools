require "docker_tools/version"
require "docker_tools/image"
require "docker_tools/run"
require "docker_tools/debootstrap"
require "docker_tools/dependency"
require "docker"

module DockerTools
  #Default the docker url to docker http service
  Docker.url = 'http://localhost:4243'

  def default_dependency_fallback_tag
    'latest'
  end

  def env_dependency_fallback_tag
    ENV['DOCKER_DEPENDENCY_FALLBACK_TAG']
  end

  def dependency_fallback_tag
    @dependency_fallback_tag ||= env_dependency_fallback_tag || default_dependency_fallback_tag
  end

  def dependency_fallback_tag=(new_dependency_fallback_tag)
    @dependency_fallback_tag = new_dependency_fallback_tag
  end

  def image_timeout
    @image_timeout = 1000
  end

  def image_timeout=(new_image_timeout)
    @image_timeout = new_image_timeout
  end

  module_function :default_dependency_fallback_tag, :env_dependency_fallback_tag,
                  :dependency_fallback_tag, :dependency_fallback_tag=,
                  :image_timeout, :image_timeout=
end
