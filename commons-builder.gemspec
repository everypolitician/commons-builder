
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'commons/builder/version'

Gem::Specification.new do |spec|
  spec.name          = 'commons-builder'
  spec.version       = Commons::Builder::VERSION
  spec.authors       = ['Louise Crow', 'Mark Longair']
  spec.email         = ['parliaments@mysociety.org']

  spec.summary       = 'Build scripts for Democratic Commons repos'
  spec.homepage      = 'https://github.com/everypolitician/commons-builder'
  spec.license       = 'MIT'

  spec.required_ruby_version = '~> 2.4.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables = ['build']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_dependency 'rest-client', '~> 2.0.2'


end
