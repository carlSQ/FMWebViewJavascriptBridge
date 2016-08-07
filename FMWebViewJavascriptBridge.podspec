
Pod::Spec.new do |s|
  s.name             = "FMWebViewJavascriptBridge"
  s.version          = "1.0.2"
  s.summary          = "ios js bridge"

  s.description      = <<-DESC
                         FMWebViewJavascriptBridge inspired by WebViewJavascripBridge and react native
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
