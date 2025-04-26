{
  description = "A very basic flake";

  outputs = {self, ...}: {
    templates = {
      mitsuba3 = {
        path = "./mitsuba3";
        description = "Build environment for Dr.Jit and Mitsbua3";
      };
    };
  };
}
