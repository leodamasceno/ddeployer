require 'yaml'
require 'docker'
require 'logger'
require 'yajl'
require 'net/http'
require 'uri'

log_file = "/var/log/ddeployer.log"
config_file = "ddeployer.yaml"
option = ARGV[0]

@log = Logger.new("#{log_file}")

def encryptString(string,config_file)
  config = YAML.load(File.read(config_file))
  public_key_file = config['keys']['public_key']
  public_key = OpenSSL::PKey::RSA.new(File.read(public_key_file))
  encrypted_string = Base64.strict_encode64(public_key.public_encrypt(string))
  encrypted_string
end

def decryptString(encrypted_string,config_file)
  config = YAML.load(File.read(config_file))
  private_key_file = config['keys']['private_key']
  private_key = OpenSSL::PKey::RSA.new(File.read(private_key_file))
  string = private_key.private_decrypt(Base64.decode64(encrypted_string))
  string
end

def localDeploy(config_file,image_tag)
  if ! File.exist?("Dockerfile")
    @log.debug "[ERROR] Couldn't find Dockerfile in project's directory"
    abort("[Error] Create the Dockerfile inside your project's directory")
  end
  config = YAML.load(File.read(config_file))
  image_name = config['config']['docker_image_name']
  url = config['config']['docker_url']
  username = config['config']['docker_login']
  password = decryptString(config['config']['docker_password'],config_file)
  Docker.authenticate!(
    'username' => username,
    'password' => password,
    'email' => '',
    'serveraddress' => url
  )
  parser = Yajl::Parser.new
  parser.on_parse_complete = ->(obj) { print obj['stream'] }
  docker_image = Docker::Image.build_from_dir('.', { 'dockerfile' => 'Dockerfile' }) do |v|
    output = parser.parse(v)
    if output != ''
      puts output
    end
  end
  docker_image.tag('repo' => image_name, 'tag' => image_tag)
  container = Docker::Container.create(
    'Image' => "#{image_name}:#{image_tag}",
    'Tty'   => true
  )
  container.start
end

def remoteDeploy(parameters,config_file)
  config = YAML.load(File.read(config_file))
  url = config['config']['jenkins_url']
  job_name = config['config']['jenkins_job_name']
  job_token = decryptString(config['config']['jenkins_job_token'],config_file)

  if parameters == ''
    uri = URI.parse("#{url}/buildByToken/build?job=#{job_name}&token=#{job_token}")
  else
    uri = URI.parse("#{url}/buildByToken/buildWithParameters?job=#{job_name}&token=#{job_token}&#{parameters}")
  end

  response = Net::HTTP.get_response(uri)

  if response.code == '201'
    puts "[INFO] Triggered job successfully"
  else
    puts "[ERROR] An error occurred while trying to trigger the job. Please follow the instructions to allow access to Jenkins"
  end

end

case option
when "-e"
  string = ARGV[1]
  @log.debug "[INFO] Encrypting string"
  puts encryptString(string,config_file)
when "-d"
  encrypted_string = ARGV[1]
  @log.debug "[INFO] Decrypting key"
  puts decryptString(encrypted_string,config_file)
when "-t"
  image_tag = ARGV[1]
  localDeploy(config_file,image_tag)
when "-r"
  if ARGV[1] == '-p'
    parameters = ARGV[2]
    remoteDeploy(parameters,config_file)
  else
    remoteDeploy("",config_file)
  end
else
  puts "[INFO] You need to specify one of the following options:"
  puts "-e: Encrypt a string"
  puts "-d: Decrypt a password"
  puts "-t: Tag a Docker image to be deployed locally"
  puts "-r: Trigger a job in a remote Jenkins server"
  puts "  -p: Specify parameters"
end
