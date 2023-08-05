{
  users = {
    mutableUsers = false;
    users.user = {
      isNormalUser = true;
      initialHashedPassword = "$y$j9T$t/JLlePX4G9z5V4xdJXCV1$7kWMxU3Sc0IOpvoTqXzk2U2es2hdMDLUGytnvTgx282";  # printf password | mkpasswd -s
      home = "/home/user";
      extraGroups = [
        "wheel"
        "docker"
        #"podman"
        #"render"
        #"video"
        #"networkmanager"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5ZoG0AtQlWgFJaIYnRznbgxQ/NQEvQunUzHcXgAT/p nixos"  # ssh-keygen -t ed25519 -f </folder/keyfile> -C <comment>
      ];
      # packages = with pkgs; [
      #   tree
      # ];
    };
  };
}