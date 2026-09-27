_: {
  programs.niri.settings.layer-rules = [
    {
      matches = [ { namespace = "^pana-notif-toast$"; } ];
      block-out-from = "screencast";
    }
  ];
}
