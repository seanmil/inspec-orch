# coding: utf-8
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'inspec-orch/version'

Gem::Specification.new do |spec|
  spec.name        = 'inspec-orch'
  spec.version     = InspecPlugins::Orch::VERSION
  spec.authors     = ['Sean Millichamp']
  spec.email       = ['sean@bruenor.org']
  spec.summary     = 'InSpec plugin to run InSpec profiles against Puppet Enterprise PCP targets.'
  spec.description = 'Run InSpec against Puppet Enterprise Orchestrator PCP targets.'
  spec.homepage    = 'https://github.com/seanmil/inspec-orch'
  spec.license     = 'Apache-2.0'

  spec.files = %w{
    README.md inspec-orch.gemspec Gemfile
  } + Dir.glob(
    '{bin,docs,examples,lib,tasks}/**/*', File::FNM_DOTMATCH
  ).reject { |f| File.directory?(f) }

  spec.require_paths = ['lib']

  spec.add_dependency 'inspec', '>=2.3', '<4.0.0'
  spec.add_dependency 'train-pcp'
end
