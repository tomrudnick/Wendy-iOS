#
# Be sure to run `pod lib lint Wendy-iOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Wendy-iOS'
  s.version          = '0.1.0'
  s.summary          = 'Build offline first iOS mobile apps. Remove loading screens, perform tasks instantly.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Wendy is an iOS library designed to help you make your app offline-first. Use Wendy to define sync tasks, then Wendy will run those tasks periodically to keep your app's device offline data in sync with it's online remote storage.

Wendy is a FIFO task runner. You give it tasks, one by one, it persists those tasks to storage, then when Wendy has determined it's a good time for your task to run, it will call your task's sync function to perform a sync. If your user's device is online and has a good amount of battery, Wendy goes through all of the tasks available one by one running them to succeed or fail and try again.
                       DESC

  s.homepage         = 'https://github.com/levibostian/Wendy-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Levi Bostian' => 'levi.bostian@gmail.com' }
  s.source           = { :git => 'https://github.com/levibostian/Wendy-iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Wendy-iOS/Classes/**/*'
  
  s.resource_bundles = {
    'Wendy-iOS' => ['Wendy-iOS/**/*.xcdatamodeld']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CoreData'
  # s.dependency 'AFNetworking', '~> 2.3'
end
