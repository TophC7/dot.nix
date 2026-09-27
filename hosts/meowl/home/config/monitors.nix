{ gpu, ... }:
{
  monitors = [
    {
      name = gpu.connector;
      primary = true;
      width = 2560;
      height = 1440;
      refreshRate = 60;
      x = 0;
      y = 0;
      scale = 1.0;
      transform = 0;
      enabled = true;
    }
  ];
}
