# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # For now, test on yosemite+mavericks, sort out linux/bsd later
  config.vm.define "yosemite", primary: true do |yosemite|
    yosemite.vm.box = "yosemite"
    yosemite.vm.provider "vmware_fusion" do |v|
      v.gui = true
      v.vmx["memsize"] = "4096"
      v.vmx["numvcpus"] = "4"
    end
  end

  config.vm.define "mavericks" do |mavericks|
    mavericks.vm.box = "mavericks"
    mavericks.vm.provider "vmware_fusion" do |v|
      v.gui = true
      v.vmx["memsize"] = "4096"
      v.vmx["numvcpus"] = "4"
    end
  end

  # TODO: sort out how I can do shell provision first go, then
  # provision via ansible from there on out
  config.vm.provision "shell",
                      privileged: false,
                      keep_color: true,
                      inline: "/vagrant/bootstrap.sh"
end
