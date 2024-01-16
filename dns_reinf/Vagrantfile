Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |vb|
      vb.memory = 256
      vb.linked_clone = true
  end

  # method to create the machines
  def create_machine(config, name, box, hostname, provision, ip_address)
      config.vm.define name do |node|
          node.vm.box = box
          node.vm.hostname = hostname
          node.vm.network :private_network, type: "static", ip: ip_address
          node.vm.provision "shell", path: provision
      end
  end

  # creation of the machines
  create_machine(config, "ns1", "debian/bullseye64", "ns1.dani.com", "provision.sh", "192.168.57.10")
  create_machine(config, "ns2", "debian/bullseye64", "ns2.dani.com", "provision.sh", "192.168.57.11")

end