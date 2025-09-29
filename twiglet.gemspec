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

  # Required metadata for trusted publishing
  gem.metadata = {
    'source_code_uri'   => 'https://github.com/simplybusiness/twiglet-ruby',
    'changelog_uri'     => 'https://github.com/simplybusiness/twiglet-ruby/releases',
    'bug_tracker_uri'   => 'https://github.com/simplybusiness/twiglet-ruby/issues',
    'documentation_uri' => 'https://github.com/simplybusiness/twiglet-ruby'
  }

  gem.files                 = `git ls-files`.split("\n")

  gem.require_paths         = ['lib']
  gem.required_ruby_version = ['>= 3.1 ', '< 3.5']

  gem.license               = 'Copyright SimplyBusiness'

  gem.add_dependency 'json-schema'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'simplecov', '0.17.1'
  gem.add_development_dependency 'simplycop'
end
