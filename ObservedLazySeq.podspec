#
# Be sure to run `pod lib lint ObservedLazySeq.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ObservedLazySeq'
  s.version          = '0.1.0'
  s.summary          = 'Wrapper for Taking&observing things from database, lazy way.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This pod focuses on building wrapper for objects that are:
1. Loaded lazily, like batch requests from database
2. Observed and updated
3. May need transformation on the way
                       DESC

  s.homepage         = 'https://github.com/NeedMoreDesu/ObservedLazySeq.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Oleksii Horishnii' => 'oleksii.horishnii@gmail.com' }
  s.source           = { :git => 'https://github.com/NeedMoreDesu/ObservedLazySeq.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'ObservedLazySeq/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ObservedLazySeq' => ['ObservedLazySeq/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'LazySeq'
end
