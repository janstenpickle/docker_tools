module DockerTools::Util
  module_function

  def parse_output(body, &block)
    begin
      if body.include?('}{')
        body.split('}{').each do | line |
          line = "{#{line}" unless line =~ /^{/
          line = "#{line}}" unless line =~ /}$/
          block.call(Docker::Util.parse_json(line))
        end
      else
        block.call(Docker::Util.parse_json(body))
      end
    rescue
      puts 'WARN: Could not parse output from docker:'
      puts body
    end
  end
end
