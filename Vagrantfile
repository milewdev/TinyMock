VAGRANTFILE_API_VERSION   = "2"
PROJECT_SOURCE_URL        = "https://github.com/milewgit/TinyMockJS.git"
PROJECT_VM_PATH           = "/Users/vagrant/Documents/TinyMockJS"
PROVIDER                  = :vmware_fusion
BOX                       = "OSX109"


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  select_box                      config, BOX
  configure_provider              config, PROVIDER
  setup_synced_folders            config
  install_osx_command_line_tools  config  # needed by git
  install_gpg                     config  # needed in order to sign git commits
  install_git                     config
  install_git_gui                 config
  install_node                    config
  install_editor                  config
  install_project_source_code     config, PROJECT_SOURCE_URL, PROJECT_VM_PATH
  install_project_dependencies    config, PROJECT_VM_PATH
  reboot                          config
end


def select_box(config, box)
  config.vm.box = box
end


def configure_provider(config, vm)
  config.vm.provider(vm) do |vb|
    vb.gui = true
  end
end


def setup_synced_folders(config)
  config.vm.synced_folder "~/", "/.vagrant_host_home"
end


def install_osx_command_line_tools(config)
  say config, "Installing OS X command line tools"
  install_dmg config, 
    'https://s3.amazonaws.com/OHSNAP/command_line_tools_os_x_mavericks_for_xcode__late_october_2013.dmg', 
    'Command Line Developer Tools',
    'Command Line Tools (OS X 10.9).pkg'
end


def install_gpg(config)  
  say config, "Installing gpg, gpg-agent, and copying gpg keys from vm host"
  install_dmg config,
    'https://releases.gpgtools.org/GPG%20Suite%20-%202013.10.22.dmg',
    'GPG Suite', 
    'Install.pkg'
  run_script config, <<-'EOF'
    sudo rm -rf /Users/vagrant/.gnupg
    sudo rsync -r --exclude '.gnupg/S.gpg-agent' /.vagrant_host_home/.gnupg /Users/vagrant
    sudo chown -R vagrant /Users/vagrant/.gnupg
  EOF
end


def install_git(config)
  say config, "Installing git and copying .gitconfig from vm host"
  install_dmg config,
    'https://git-osx-installer.googlecode.com/files/git-1.8.4.2-intel-universal-snow-leopard.dmg',
    'Git 1.8.4.2 Snow Leopard Intel Universal',
    'git-1.8.4.2-intel-universal-snow-leopard.pkg'
  run_script config, "cp /.vagrant_host_home/.gitconfig /Users/vagrant/.gitconfig"
end


def install_git_gui(config)
  say config, "Installing GitHub for Mac"
  run_script config, "curl -fsSL https://central.github.com/mac/latest | sudo tar -x -C /Applications -f -"
end


def install_node(config)
  say config, "Installing nodejs"
  install_pkg config, 'http://nodejs.org/dist/v0.10.26/node-v0.10.26.pkg'
end


def install_editor(config)
  say config, "Installing editor (TextMate)"
  run_script config, "curl -fsSL https://api.textmate.org/downloads/release | sudo tar -x -C /Applications -f -"
end


def install_project_source_code(config, project_source_url, project_vm_path)
  say config, "Installing project source code"
  run_script config, "git clone #{project_source_url} #{project_vm_path}"
end


def install_project_dependencies(config, project_vm_path)
  say config, "Install project dependencies"
  run_script config, "( cd #{project_vm_path} && exec npm install )"
end


def reboot(config)
  say config, "Rebooting"
  run_script config, "sudo reboot"
end


def install_dmg(config, url, path, pkg)
  path = '/Volumes/' + escape_shell_special_chars(path)
  pkg = escape_shell_special_chars(pkg)
  run_script config, <<-"EOF"
    curl -o vm_install.dmg #{url}
    hdiutil attach vm_install.dmg
    sudo installer -pkg #{path}/#{pkg} -target /
    hdiutil detach #{path}
    rm -f vm_install.dmg
  EOF
end


def install_pkg(config, url)
  run_script config, <<-"EOF"
    curl -o vm_install.pkg #{url}
    sudo installer -pkg vm_install.pkg -target /
    rm -f vm_install.pkg
  EOF
end


def escape_shell_special_chars(string)
  string.gsub(/([ ()])/, '\\\\\1')        # 'my product (v1)' => 'my\ product\ \(v1\)'
end


def say(config, message)
  run_script config, "echo '--------------- #{message} ---------------'"
end


def run_script(config, script)
  config.vm.provision :shell, privileged: false, inline: script
end
