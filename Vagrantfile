# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = "ubuntu-server-14.04.2"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"

  # Boot with a GUI so you can see the screen. (Default is headless)
  # config.vm.boot_mode = :gui

  # enable bridged networking
  #config.vm.network :bridged, :bridge=>ENV["VIRTUALBOX_BRIDGE_ADAPTER"]

end

# provider-specfic configuration
Vagrant.configure("2") do |config|
  # enable private networking
  config.vm.network "private_network", type: "dhcp"

  config.vm.provider :virtualbox do |vb|
    # enable 4 CPUs by default
  	vb.customize ["modifyvm", :id, "--cpus", "2", "--memory", "2048"]

    # change the network card hardware for better performance
    vb.customize ["modifyvm", :id, "--nictype1", "virtio" ]
    vb.customize ["modifyvm", :id, "--nictype2", "virtio" ]

    # suggested fix for slow network performance
    # see https://github.com/mitchellh/vagrant/issues/1807
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end
end
