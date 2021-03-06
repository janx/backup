# encoding: utf-8

require File.expand_path('lib/backup/version')

Gem::Specification.new do |gem|
  gem.name        = 'backup'
  gem.version     = Backup::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = 'Michael van Rooijen'
  gem.email       = 'meskyanichi@gmail.com'
  gem.homepage    = 'https://github.com/meskyanichi/backup'
  gem.license     = 'MIT'
  gem.summary     = 'Provides an elegant DSL in Ruby for performing backups on UNIX-like systems.'
  gem.description = <<-EOS.gsub(/\s+/, ' ').strip
    Backup is a RubyGem, written for UNIX-like operating systems, that allows you to easily perform backup operations
    on both your remote and local environments. It provides you with an elegant DSL in Ruby for modeling your backups.
    Backup has built-in support for various databases, storage protocols/services, syncers, compressors, encryptors
    and notifiers which you can mix and match. It was built with modularity, extensibility and simplicity in mind.
  EOS

  gem.files = %x[git ls-files -- lib bin templates README.md LICENSE.md].split("\n")
  gem.require_path  = 'lib'
  gem.executables   = ['backup']

  # Gem Dependencies
  # Generated by `rake gemspec`. Do Not Edit.
  gem.add_dependency 'builder', '= 3.2.2'
  gem.add_dependency 'dropbox-sdk', '= 1.5.1'
  gem.add_dependency 'excon', '= 0.25.3'
  gem.add_dependency 'faraday', '= 0.8.7'
  gem.add_dependency 'fog', '= 1.13.0'
  gem.add_dependency 'formatador', '= 0.2.4'
  gem.add_dependency 'hipchat', '= 0.11.0'
  gem.add_dependency 'httparty', '= 0.11.0'
  gem.add_dependency 'json', '= 1.8.0'
  gem.add_dependency 'mail', '= 2.5.4'
  gem.add_dependency 'mime-types', '= 1.23'
  gem.add_dependency 'multi_json', '= 1.7.7'
  gem.add_dependency 'multi_xml', '= 0.5.4'
  gem.add_dependency 'multipart-post', '= 1.2.0'
  gem.add_dependency 'net-scp', '= 1.1.2'
  gem.add_dependency 'net-sftp', '= 2.1.2'
  gem.add_dependency 'net-ssh', '= 2.6.8'
  gem.add_dependency 'nokogiri', '= 1.5.10'
  gem.add_dependency 'open4', '= 1.3.0'
  gem.add_dependency 'polyglot', '= 0.3.3'
  gem.add_dependency 'qiniu-rs', '= 3.4.5'
  gem.add_dependency 'rest-client', '= 1.6.7'
  gem.add_dependency 'ruby-hmac', '= 0.4.0'
  gem.add_dependency 'simple_oauth', '= 0.2.0'
  gem.add_dependency 'thor', '= 0.18.1'
  gem.add_dependency 'treetop', '= 1.4.14'
  gem.add_dependency 'twitter', '= 4.8.1'
end
