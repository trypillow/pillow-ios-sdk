Pod::Spec.new do |s|
  s.name             = 'PillowSDK'
  s.version          = '1.0.0'
  s.summary          = 'Pillow iOS SDK - Native iOS integration for Pillow chat services'
  s.description      = <<-DESC
    The Pillow iOS SDK provides a native iOS interface for integrating Pillow chat services
    into your iOS applications. Features include webview-based chat interface, message banners,
    notification management, and JavaScript bridge communication.
  DESC
  
  s.homepage         = 'https://github.com/trypillow/pillow-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tape Labs' => 'hello@tape.sh' }
  s.source           = { :git => 'https://github.com/trypillow/pillow-ios-sdk.git', :tag => "v#{s.version}" }
  
  s.ios.deployment_target = '16.0'
  s.swift_version = '5.9'
  
  s.source_files = 'Sources/PillowSDK/**/*.swift'
  
  s.frameworks = 'UIKit', 'WebKit', 'SwiftUI', 'UserNotifications'
  
  s.requires_arc = true
end

