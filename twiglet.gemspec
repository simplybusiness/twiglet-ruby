# frozen_string_literal: true

require File.expand_path('lib/twiglet/version', __dir__)

$LOAD_PATH.push File.expand_path('lib', __dir__)

Gem::Specification.new do |gem|
  gem.name                  = 'twiglet'
  gem.version               = Twiglet::VERSION
  gem.authors               = ['Simply Business']
  gem.email                 = ['tech@simplybusiness.co.uk']
  gem.homepage              = 'https://github.com/simplybusiness/twiglet-ruby'

  gem.summary               = 'Twiglet'
  gem.description           = 'Like a log, only smaller.'

  gem.files                 = `git ls-files`.split("\n")

  gem.require_paths         = ['lib']
  gem.required_ruby_version = '>= 3.0'

  gem.license               = 'Copyright SimplyBusiness'

  gem.add_dependency 'json-schema'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'simplecov', '0.17.1'
  gem.add_development_dependency 'simplycop'
end
