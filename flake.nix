{
  description = "A very basic flake";

  outputs = {self, ...}: {
    templates = {
      mitsuba3 = {
        path = ./mitsuba3;
        description = "Build environment for Dr.Jit and Mitsbua3";
      };
      writeup = {
        path = ./writeup;
        description = "LaTeX development environment";
      };
      typst = {
        path = ./typst;
        description = "Typst development environment";
      };
    };
  };
}
