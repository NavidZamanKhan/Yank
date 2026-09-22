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
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  source_dir = File.directory?(File.expand_path('receive_sharing_intent/Sources', __dir__)) ? 'receive_sharing_intent/Sources/receive_sharing_intent' : '.symlinks/plugins/receive_sharing_intent/ios/receive_sharing_intent/Sources/receive_sharing_intent'

  s.source_files = "#{source_dir}/**/*.swift"
  s.dependency 'Flutter'
end
