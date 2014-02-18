# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'simple_crawler'
  spec.version       = '0.0.1'
  spec.authors       = ['anupom']
  spec.email         = ['anupom.syam@gmail.com']
  spec.summary       = %q{Create sitemap from a given url}
  spec.description   = %q{Simple web crawler to crawl a domain and generate sitemap}
  spec.homepage      = 'https://github.com/anupom/crawler'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 10.1'
  spec.add_development_dependency 'simplecov', '~> 0.8'
  spec.add_development_dependency 'webmock', '~> 1.17'
end
