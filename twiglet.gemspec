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
  gem.test_files            = `git ls-files -- {test}/*`.split("\n")

  gem.require_paths         = ['lib']
  gem.required_ruby_version = '>= 2.5'

  gem.license               = 'Copyright SimplyBusiness'
end
