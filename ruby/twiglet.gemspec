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
  gem.version               = '1.0.0'
  gem.authors               = ['Simply Business']
  gem.email                 = ['tech@simplybusiness.co.uk']
  gem.homepage              = 'https://github.com/simplybusiness/twiglet'

  gem.summary               = %q{Twiglet}
  gem.description           = %q{Like a log, only smaller.}

  gem.files                 = `git ls-files`.split("\n")
  gem.test_files            = `git ls-files -- {test}/*`.split("\n")

  gem.require_paths         = ['lib']
  gem.required_ruby_version = '>= 2.0'

  gem.license               = 'Copyright SimplyBusiness'
end
