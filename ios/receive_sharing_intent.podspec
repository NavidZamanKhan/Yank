Pod::Spec.new do |s|
  s.name             = 'receive_sharing_intent'
  s.version          = '1.9.0'
  s.summary          = 'A flutter plugin that enables flutter apps to receive sharing photos from other apps.'
  s.description      = <<-DESC
A flutter plugin that enables flutter apps to receive sharing photos from other apps.
                       DESC
  s.homepage         = 'https://github.com/KasemJaffer/receive_sharing_intent'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Kasem' => 'kasem.jaffer@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = '.symlinks/plugins/receive_sharing_intent/ios/receive_sharing_intent/Sources/receive_sharing_intent/**/*.swift'
  s.dependency 'Flutter'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
end
