#
# Be sure to run `pod spec lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about the attributes see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = "CorpFramework"
  s.version          = "0.0.5"
  s.summary          = "Ctrip Corp Framework."
  s.description      = <<-DESC
                       An optional longer description of CorpFramework

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "http://www.apblog.cn"
  s.license          = 'MIT'
  s.author           = { "Klaus Liu" => "lpluck08@gmail.com" }
  s.source           = { :git => "https://github.com/KlausLiu/CorpFramework.git", :tag => "0.0.5" }

  s.platform     = :ios

  s.subspec 'Base64' do |base64|
    base64.source_files = 'Framework/Vendor/Base64/*.{h,m}'
    base64.requires_arc = false
  end

  s.subspec 'JSONKit' do |json|
    json.source_files = 'Framework/Vendor/JSONKit/*.{h,m}'
    json.requires_arc = false
  end

  s.subspec 'IdentifierAddition' do |ia|
    ia.source_files = 'Framework/Vendor/IdentifierAddition/*.{h,m}'
    ia.requires_arc = false
  end

  s.subspec 'WebViewJavascriptBridge' do |wvjb|
    wvjb.source_files = 'Framework/Vendor/WebViewJavascriptBridge/*.{h,m}'
    wvjb.resource     = 'Framework/Vendor/WebViewJavascriptBridge/CorpWebViewJavascriptBridge.js.txt'
    wvjb.requires_arc = false
  end

  s.subspec 'Core' do |core|
    core.source_files = 'Framework/*.{h,m,mm}', 'Framework/MVC/*.{h,m,mm}', 'Framework/MVC/**/*.{h,m,mm}', 'Framework/MVC/**/**/*.{h,m,mm}', 'Framework/MVC/**/**/**/*.{h,m,mm}', 'Framework/MVC/**/**/**/**/*.{h,m}', 'Framework/System/DB/*.{h,m}', 'Framework/System/Utils/*.{h,m}', 'Framework/Categories/*.{h,m}'
    core.resource = 'Framework/System/DB/kdb_config.json'
    core.requires_arc = false
    core.dependency 'ASIHTTPRequest'
    core.dependency 'Reachability'
    core.dependency 'FMDB'
    core.dependency 'OpenUDID'
    core.dependency 'CorpFramework/JSONKit'
    core.dependency 'CorpFramework/Base64'
  end

end
