# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'MVVM' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'RxSwift',    '~> 3.0'
  pod 'RxCocoa',    '~> 3.0'
  pod 'NSObject+Rx'

  # Pods for MVVM

  target 'MVVMTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'MVVMUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
