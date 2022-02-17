Pod::Spec.new do |s|
s.name             = "Segment-ComScore"
s.version          = "4.4.2"
s.summary          = "ComScore Integration for Segment's analytics-ios library."

s.description      = <<-DESC
Analytics for iOS provides a single API that lets you
integrate with over 100s of tools.

This is the ComScore integration for the iOS library.
DESC

s.homepage         = "http://segment.com/"
s.license          =  { :type => 'MIT' }
s.author           = { "Segment" => "friends@segment.com" }
s.source           = { :git => "https://github.com/segment-integrations/analytics-ios-integration-comscore.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/segment'

s.ios.deployment_target = '9.0'
s.tvos.deployment_target = '9.0'
s.requires_arc = true

s.source_files = 'Segment-ComScore/Classes/**/*'

s.dependency 'Analytics'
s.dependency 'ComScore', '~> 6.10.0'
end
