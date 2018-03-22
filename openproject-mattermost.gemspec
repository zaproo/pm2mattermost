# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/mattermost/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-mattermost"
  s.version     = OpenProject::Mattermost::VERSION
  s.authors     = "Zaproo"
  s.email       = "zaproo@zaproo.com"
  s.homepage    = "https://github.com/zaproo/pm2mattermost"
  s.summary     = 'OpenProject Mattermost'
  s.description = "Integration OpenProject with Mattermost"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.md README.md)

  s.add_dependency "rails", "~> 5.0"
end
