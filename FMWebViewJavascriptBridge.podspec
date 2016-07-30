
Pod::Spec.new do |s|
  s.name             = "FMWebViewJavascriptBridge"
  s.version          = "1.0.1"
  s.summary          = "FMWebViewJavascriptBridge inspired by WebViewJavascripBridge and react native"

  s.description      = <<-DESC
                         ios js bridge
                       DESC

  s.homepage         = "https://github.com/carlSQ/FMWebViewJavascript"
  s.license          = 'MIT'
  s.author           = { "carl shen" => "yuzhoulangzik@126.com" }
  s.source           = { :git => "https://github.com/carlSQ/FMWebViewJavascript.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files  = 'Classes/*.{h,m}'
  s.resource     = 'Classes/FMWebViewJavascriptBridge.js.txt'
  s.public_header_files ='Classes/*.h'
  s.frameworks = 'UIKit', 'WebKit'
end
