# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

Gem::Specification.new do |gem|
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the
  # 'allowed_push_host' to allow pushing to a single host or delete this section
  # to allow pushing to any host.
  if gem.respond_to?(:metadata)
    gem.metadata['allowed_push_host'] = 'https://gemstash.simplybusiness.io/private'
  else
    raise 'RubyGems 2.2 or newer is required to protect against public gem pushes.'
  end

  gem.name                  = 'twiglet'
  gem.version               = '2.0.0'
  gem.authors               = ['Simply Business']
  gem.email                 = ['tech@simplybusiness.co.uk']
  gem.homepage              = 'https://github.com/simplybusiness/twiglet'

  gem.summary               = 'Twiglet'
  gem.description           = 'Like a log, only smaller.'

  gem.files                 = `git ls-files`.split("\n")
  gem.test_files            = `git ls-files -- {test}/*`.split("\n")

  gem.require_paths         = ['lib']
  gem.required_ruby_version = '>= 2.0'

  gem.license               = 'Copyright SimplyBusiness'
end
