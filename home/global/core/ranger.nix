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
    ];
    settings = {
      show_hidden = true;
      # preview_images = true;
      # preview_images_method = w3m;
    };
  };
}
