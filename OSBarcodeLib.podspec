Pod::Spec.new do |spec|
  spec.name                   = 'OSBarcodeLib'
  spec.version                = '2.1.1'
  spec.summary                = 'Barcode scanner library for iOS with highlight, delay, and vibration features'
  spec.description            = 'The OSBarcodeLib is a library built using Swift that offers you a barcode scanner for your iOS application. SecuraStock fork with barcode highlighting, configurable close delay, and vibration feedback.'

  spec.homepage               = 'https://github.com/SecuraStockLLC/OSBarcodeLib-iOS'
  spec.license                = { :type => 'MIT', :file => 'LICENSE' }
  spec.author                 = { 'SecuraStock' => 'dev@securastock.com' }

  # Source from git repo, not precompiled binary
  spec.source                 = {
    :git => 'https://github.com/SecuraStockLLC/OSBarcodeLib-iOS.git',
    :branch => 'securastock'
  }

  # Compile from source files
  spec.source_files           = 'Sources/OSBarcodeLib/**/*.{swift,h,m}'

  # Include resources (xcassets for scanner UI)
  spec.resources              = 'Sources/OSBarcodeLib/**/*.xcassets'

  spec.ios.deployment_target  = '14.0'
  spec.swift_versions         = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '5.10']

  # Required frameworks for camera and barcode scanning
  spec.frameworks             = 'AVFoundation', 'Vision', 'UIKit', 'SwiftUI', 'AudioToolbox'
end
