ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

if Gem.win_platform?
  require "ruby_installer/runtime"

  vips_bin = ENV["PATH"].to_s.split(File::PATH_SEPARATOR).find do |dir|
    File.exist?(File.join(dir, "libvips-42.dll"))
  end
  RubyInstaller::Runtime.add_dll_directory(vips_bin) if vips_bin
end

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
