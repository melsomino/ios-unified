Pod::Spec.new do |spec|
  spec.name = 'Unified'
  spec.version = '0.1.8'
  spec.summary = 'Unified framework'
  spec.license = { :type => 'MIT' }
  spec.homepage = 'https://github.com/melsomino/unified-ios'
  spec.authors = 'Michael Vlasov'
  spec.source = { :git => 'https://github.com/melsomino/unified-ios', :tag => 'rc-' + spec.version.to_s }
  
  spec.platform = :ios, '8.0'
  spec.requires_arc = true


  spec.source_files = 'Unified/**/*.{h,m,swift}'
  spec.resources = 'Unified/**/*.{xib,storyboard,xcassets,sql,uni}'

  spec.dependency 'GRDB.swift'
  spec.dependency 'Starscream', '~> 1.1.3'
  spec.dependency 'Fuzi', '~> 0.3.0'
end