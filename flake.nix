{ outputs = { ... }: {
    templates.default = {
      description = "Flake setup for Haskell packages";

      path = ./template;
    };
  };
}
