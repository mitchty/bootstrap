# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # For now, test on yosemite+mavericks, sort out linux/bsd later
  config.vm.define "yosemite", primary: true do |yosemite|
    yosemite.vm.network "public_network"
    yosemite.vm.box = "yosemite"
    yosemite.vm.provider "vmware_fusion" do |v|
      v.gui = true
      v.vmx["memsize"] = "8192"
      v.vmx["numvcpus"] = "6"
    end
  end

  # TODO: sort out how I can do shell provision first go, then
  # provision via ansible from there on out
  config.vm.provision "shell",
                      privileged: false,
                      keep_color: true,
                      inline: "
env SKIP_HOMEBREW=#{ENV["SKIP_HOMEBREW"]} SKIP_NIX=#{ENV["SKIP_NIX"]} /vagrant/bootstrap.sh
"
end
