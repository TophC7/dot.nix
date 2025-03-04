{
  programs.ranger = {
    enable = true;
    plugins = [
      {
        name = "zoxide";
        src = builtins.fetchGit {
          url = "https://github.com/jchook/ranger-zoxide.git";
          rev = "281828de060299f73fe0b02fcabf4f2f2bd78ab3";
        };
      }
      {
        name = "archives";
        src = builtins.fetchGit {
          url = "https://github.com/maximtrp/ranger-archives.git";
          rev = "b4e136b24fdca7670e0c6105fb496e5df356ef25";
        };
      }
    ];
    settings = {
      show_hidden = true;
      # preview_images = true;
      # preview_images_method = w3m;
    };
  };
}
