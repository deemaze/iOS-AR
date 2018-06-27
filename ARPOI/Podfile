platform :ios, '11.0'
 
target "ARPOI" do
	use_frameworks!

    # pod 'ARCL', :git => 'https://github.com/aclima93/ARKit-CoreLocation.git', :branch => 'multi-subnode-distance-scaling'

	post_install do |installer|
		installer.pods_project.targets.each do |target|
			target.build_configurations.each do |config|
				config.build_settings['SWIFT_VERSION'] = '4.0'
			end
		end
	end

end
