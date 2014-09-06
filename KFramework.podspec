
Pod::Spec.new do |s|
  s.name             = "KFramework"
  s.version          = "0.0.2"
  s.summary          = "Klaus Framework."
  s.description      = <<-DESC
                       MVC Framework.

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "http://www.apblog.cn"
  s.license          = 'MIT'
  s.author           = { "Klaus Liu" => "klaus_liu@163.com" }
  s.source           = { :git => "https://github.com/KlausLiu/KFramework.git", :tag => "0.0.2" }

  s.platform     = :ios
  
  s.ios.deployment_target = '5.0'

  s.subspec 'Base64' do |base64|
    base64.source_files = 'Classes/Vendor/Base64/*.{h,m}'
    base64.requires_arc = false
  end

  s.subspec 'JSONKit' do |json|
    json.source_files = 'Classes/Vendor/JSONKit/*.{h,m}'
    json.requires_arc = false
  end

  s.subspec 'IdentifierAddition' do |ia|
    ia.source_files = 'Classes/Vendor/IdentifierAddition/*.{h,m}'
    ia.requires_arc = false
  end

  s.subspec 'WebViewJavascriptBridge' do |wvjb|
    wvjb.source_files = 'Classes/Vendor/WebViewJavascriptBridge/*.{h,m}'
    wvjb.resource     = 'Classes/Vendor/WebViewJavascriptBridge/KWebViewJavascriptBridge.js.txt'
    wvjb.requires_arc = false
  end

  s.subspec 'Categories' do |c|
    c.source_files = 'Classes/Categories/*.{h,m}', 'Classes/System/Utils/*.{h,m}', 'Classes/KDefine.h'
    c.requires_arc = false
    c.dependency 'KFramework/JSONKit'
  end

  s.subspec 'DB' do |db|
    db.source_files = 'Classes/System/DB/*.{h,m}', 'Classes/KDefine.h', 'Classes/System/Utils/*.{h,m}'
    db.requires_arc = false
    db.dependency 'FMDB'
    db.dependency 'KFramework/Categories'
  end

  s.subspec 'Core' do |core|
    core.source_files = 'Classes/*.{h,m,mm}', 'Classes/MVC/*.{h,m,mm}', 'Classes/MVC/**/*.{h,m,mm}', 'Classes/MVC/**/**/*.{h,m,mm}', 'Classes/MVC/**/**/**/*.{h,m,mm}', 'Classes/MVC/**/**/**/**/*.{h,m}', 'Classes/System/Utils/*.{h,m}'
    core.requires_arc = false
    core.dependency 'AFNetworking', '~> 1.3.4'
    core.dependency 'Reachability'
    core.dependency 'OpenUDID'
    core.dependency 'KFramework/Categories'
    core.dependency 'KFramework/JSONKit'
    core.dependency 'KFramework/Base64'
  end

end
