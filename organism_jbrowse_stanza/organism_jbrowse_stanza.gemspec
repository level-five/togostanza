lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'organism_jbrowse_stanza'
  spec.version       = '0.0.1'
  spec.authors       = ['TODO: Write your name']
  spec.email         = ['']
  spec.summary       = %q{Genomic context }
  spec.description   = %q{Schematic view of the genome of the specified organism}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = Dir.glob('**/*')
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'togostanza'
end
