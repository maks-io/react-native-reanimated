require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

reactVersion = '0.0.0'
reactTargetTvOS = false
isUserApp = false

begin
  # user app
  # /appName/node_modules/react-native-reanimated/RNReanimated.podspec
  # /appName/node_modules/react-native/package.json
  reactJson = JSON.parse(File.read(File.join(__dir__, "..", "..", "node_modules", "react-native", "package.json")))
  reactVersion = reactJson["version"]
  reactTargetTvOS = reactJson["name"] == "react-native-tvos"
  isUserApp = true
rescue
  begin
    # monorepo
    # /monorepo/packages/appName/node_modules/react-native-reanimated/RNReanimated.podspec
    # /monorepo/node_modules/react-native/package.json
    reactJson = JSON.parse(File.read(File.join(__dir__, "..", "..", "..", "..", "node_modules", "react-native", "package.json")))
    reactVersion = reactJson["version"]
    reactTargetTvOS = reactJson["name"] == "react-native-tvos"
  rescue
    begin
      # Example app in reanimated repo
      # /react-native-reanimated/RNReanimated.podspec
      # /react-native-reanimated/{Example,FabricExample,TVOSExample}/node_modules/react-native/package.json
      if ENV["ReanimatedTVOSExample"] == "1" then
        appName = "TVOSExample"
      elsif ENV["RCT_NEW_ARCH_ENABLED"] == "1" then
        appName = "FabricExample"
      else
        appName = "Example"
      end
      reactJson = JSON.parse(File.read(File.join(__dir__, appName, "node_modules", "react-native", "package.json")))
      reactVersion = reactJson["version"]
      reactTargetTvOS = ENV["ReanimatedTVOSExample"] == "1"
    rescue
      # should never happen
      reactVersion = '0.68.0'
      puts "[RNReanimated] Unable to recognized your `react-native` version! Default `react-native` version: " + reactVersion
    end
  end
end

if isUserApp
  libInstances = %x[find ../../ -name "package.json" | grep "/react-native-reanimated/"]
  libInstancesArray = libInstances.split("\n")
  if libInstancesArray.length() > 1
    parsedLocation = ''
    for location in libInstancesArray
      location['../../'] = '- '
      location['/package.json'] = ''
      parsedLocation += location + "\n"
    end
    raise "[Reanimated] Multiple versions of Reanimated were detected. Only one instance of react-native-reanimated can be installed in a project. You need to resolve the conflict manually. Check out the documentation: https://docs.swmansion.com/react-native-reanimated/docs/fundamentals/troubleshooting#multiple-versions-of-reanimated-were-detected \n\nConflict between: \n" + parsedLocation
  end
end

rnVersion = reactVersion.split('.')[1]

fabric_enabled = ENV['RCT_NEW_ARCH_ENABLED'] == '1'

folly_prefix = ""
if rnVersion.to_i >= 64
  folly_prefix = "RCT-"
end

folly_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32 -DRNVERSION=' + rnVersion
folly_compiler_flags = folly_flags + ' ' + '-Wno-comma -Wno-shorten-64-to-32'
boost_compiler_flags = '-Wno-documentation'
fabric_flags = ''
if fabric_enabled
  fabric_flags = '-DRN_FABRIC_ENABLED -DRCT_NEW_ARCH_ENABLED'
end

Pod::Spec.new do |s|
  s.name         = "RNReanimated"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  RNReanimated
                   DESC
  s.homepage     = "https://github.com/software-mansion/react-native-reanimated"
  s.license      = "MIT"
  # s.license    = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author       = { "author" => "author@domain.cn" }
  s.platforms    = { :ios => "9.0", :tvos => "9.0" }
  s.source       = { :git => "https://github.com/software-mansion/react-native-reanimated.git", :tag => "#{s.version}" }

  s.source_files = [
    "ios/**/*.{mm,h,m}",
    "Common/cpp/**/*.cpp",
    "Common/cpp/headers/**/*.h"
  ]

  s.preserve_paths = [
    "Common/cpp/hidden_headers/**"
  ]

  s.pod_target_xcconfig    = {
    "USE_HEADERMAP" => "YES",
    "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ReactCommon\" \"$(PODS_TARGET_SRCROOT)\" \"$(PODS_ROOT)/#{folly_prefix}Folly\" \"$(PODS_ROOT)/boost\" \"$(PODS_ROOT)/boost-for-react-native\" \"$(PODS_ROOT)/DoubleConversion\" \"$(PODS_ROOT)/Headers/Private/React-Core\"",
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++17",
  }
  s.compiler_flags = folly_compiler_flags + ' ' + boost_compiler_flags
  s.xcconfig               = {
    "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost\" \"$(PODS_ROOT)/boost-for-react-native\" \"$(PODS_ROOT)/glog\" \"$(PODS_ROOT)/#{folly_prefix}Folly\" \"$(PODS_ROOT)/RCT-Folly\" \"${PODS_ROOT}/Headers/Public/React-hermes\" \"${PODS_ROOT}/Headers/Public/hermes-engine\"",
                               "OTHER_CFLAGS" => "$(inherited)" + " " + folly_flags + " " + fabric_flags }

  s.requires_arc = true

  s.dependency "React-Core"
  if fabric_enabled
    s.dependency "React-RCTFabric"
    s.dependency "React-Codegen"
    s.dependency "RCT-Folly"
  else
    s.dependency "#{folly_prefix}Folly"
  end
  s.dependency "RCTRequired"
  s.dependency "RCTTypeSafety"
  s.dependency "ReactCommon/turbomodule/core"
  s.dependency 'FBLazyVector'
  s.dependency 'FBReactNativeSpec'
  s.dependency 'React-Core'
  s.dependency 'React-CoreModules'
  s.dependency 'React-Core/DevSupport'
  if !reactTargetTvOS
    s.dependency 'React-RCTActionSheet'
  end
  s.dependency 'React-RCTNetwork'
  s.dependency 'React-RCTAnimation'
  s.dependency 'React-RCTLinking'
  s.dependency 'React-RCTBlob'
  s.dependency 'React-RCTSettings'
  s.dependency 'React-RCTText'
  s.dependency 'React-RCTImage'
  s.dependency 'React-Core/RCTWebSocket'
  s.dependency 'React-cxxreact'
  s.dependency 'React-jsi'
  s.dependency 'React-jsiexecutor'
  s.dependency 'React-jsinspector'
  s.dependency 'Yoga'
  s.dependency 'DoubleConversion'
  s.dependency 'glog'

  if reactVersion.match(/^0.62/)
    s.dependency 'ReactCommon/callinvoker'
  else
    s.dependency 'React-callinvoker'
  end


end

