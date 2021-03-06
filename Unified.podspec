Pod::Spec.new do |spec|

  spec.name         = 'Unified'
  spec.version      = '1'
  spec.summary      = 'Unified framework'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/melsomino/unified-ios'
  spec.authors      = 'Michael Vlasov'
  spec.source       = { :git => 'https://github.com/melsomino/unified-ios', :tag => spec.version }
  
  spec.platform     = :ios, '8.0'
  spec.requires_arc = true


  spec.source_files = 'Unified/**/*.{h,m,swift}'
  spec.resources    = 'Unified/**/*.{xib,storyboard,xcassets,sql}'

  spec.dependency   'GRDB.swift'

end