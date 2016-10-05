Pod::Spec.new do |spec|
  spec.name = 'Unified'
  spec.version = '0.1.9'
  spec.summary = 'Unified framework'
  spec.license = { :type => 'MIT' }
  spec.homepage = 'https://github.com/melsomino/unified-ios'
  spec.authors = 'Michael Vlasov'
  spec.source = { :git => 'https://github.com/melsomino/unified-ios.git', :tag => 'rc-' + spec.version.to_s }
  
  spec.platform = :ios, '8.0'
  spec.requires_arc = true

  spec.source_files = 'Unified/**/*.{h,m,swift}'
  spec.resources = 'Unified/**/*.{xib,storyboard,xcassets,sql,uni}'
  spec.module_name = 'Unified'
  spec.module_map = 'Support/module.modulemap'
  spec.library = 'xml2'

  spec.dependency 'GRDB.swift'
  spec.dependency 'Starscream'
end