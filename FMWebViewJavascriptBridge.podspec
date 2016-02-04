
Pod::Spec.new do |s|
  s.name             = "FMWebViewJavascriptBridge"
  s.version          = "1.0.0"
  s.summary          = "A short description of FMWebViewJavascriptBridge."

  s.description      = <<-DESC
                          js call oc like android
                       DESC

  s.homepage         = "https://github.com/yuzhoulangzik/jsBridge"
  s.license          = 'MIT'
  s.author           = { "carl" => "yuzhoulangzik@126.com" }
  s.source           = { :git => "https://github.com/yuzhoulangzik/jsBridge.git", :tag => "1.0.0" }

  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files  = "Classes/*.{h,m}"
  s.resource     = "Classes/FMWebViewJavascriptBridge.js.txt"
  s.public_header_files ='Classes/**/*.h'
  s.frameworks = 'UIKit', 'WebKit'
end
