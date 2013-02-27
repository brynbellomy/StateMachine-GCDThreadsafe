Pod::Spec.new do |s|
  s.name         = "StateMachine"
  s.version      = "0.1"
  s.summary      = "State machine library for Objective-C."
  s.homepage     = "https://github.com/luisobo/StateMachine"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = { "Luis Solano Bonet" => "contact@luissolano.com" }
  s.source       = { :git => "https://github.com/luisobo/StateMachine.git", :tag => "0.1" }

  s.ios.deployment_target = '5.1'
  s.osx.deployment_target = '10.7'

  s.source_files = 'StateMachine/**/*.{h,m}'

  s.public_header_files = ['StateMachine/StateMachine.h',
    'StateMachine/LSStateMachine.h',
    'StateMachine/LSStateMachineMacros.h',
    'StateMachine/LSStateMachineTypedefs.h',
    'StateMachine/LSStateMachineDynamicAdditions.h']

  s.requires_arc = true

  s.dependency 'libextobjc/EXTScope', '>= 0.2.5'
  s.dependency 'libextobjc/EXTSynthesize', '>= 0.2.5'
  s.dependency 'libextobjc/EXTBlockMethod', '>= 0.2.5'
  s.dependency 'BrynKit', '>= 1.1.0'
  s.dependency 'BrynKit/GCDThreadsafe', '>= 1.1.0'

end
