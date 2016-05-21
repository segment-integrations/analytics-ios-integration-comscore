Pod::Spec.new do |s|
s.name             = "Segment-ComScore"
s.version          = "0.4.0"
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

s.platform     = :ios, '8.0'
s.requires_arc = true

s.source_files = 'Segment-ComScore/Classes/**/*'

s.dependency 'Analytics', '~> 3.0.7'
s.dependency 'ComScore-iOS', '~> 3.1510.231'
end