#
# Be sure to run `pod lib lint NVPictureInPicture.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NVPictureInPicture'
  s.version          = '0.5.2'
  s.summary          = 'Picture in Picture for iPhone. It lets you present content floating on top of application.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                        NVPictureInPicture lets you present your custom view controller in Picture-in-Picture view floating on top of your application.
                        The purpose of Picture in Picture is to make your application usable while playing video or on video call.
                        The size and edge insets of Picture in Picture view is customizable.
                       DESC

  s.homepage         = 'https://github.com/niteshvijay1995/NVPictureInPicture'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'niteshvijay1995' => 'niteshvijay1995@gmail.com' }
  s.source           = { :git => 'https://github.com/niteshvijay1995/NVPictureInPicture.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'NVPictureInPicture/Classes/**/*'
  
  # s.resource_bundles = {
  #   'NVPictureInPicture' => ['NVPictureInPicture/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
