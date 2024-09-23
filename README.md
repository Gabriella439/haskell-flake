# Haskell flake

This is a flake template for a Haskell project that aims to provide a high
power-to-weight ratio and clear instructions for the most common workflows.

In particular:

- the provided flake only depends on functionality from Nixpkgs

- the template covers most Nix tweaks you'll need in practice

- the flake is short and clear

## Usage

Run the following commands within a Git checkout of your Haskell package:

```ShellSession
$ nix flake init --template github:Gabriella439/haskell-flake
```

… then edit `flake.nix` to replace all occurrences of `${name}` with your
package's name.

Once you've done that then you can enter the Nix shell using `nix develop`:

```ShellSession
$ nix develop
```

… and inside that shell you can run `code .` to edit your Haskell package using
VSCode, which will already have the right Haskell plugins installed along with
a Haskell language server.

### `direnv`

If you use `direnv` then instead of using `nix develop` you can add this line
to your `.envrc`:

```bash
use flake .
```

> [!TIP]
> If you use `direnv` to provide your Nix shell, consider using
> [`nix-direnv`](https://github.com/nix-community/nix-direnv) to improve the
> experience.

## How to tweak the build

### Local dependencies

You can depend on a local checkout of one of your dependencies by editing the
`packageSourceOverrides` section, like this:

```nix
                (hlib.packageSourceOverrides {
                  ${name} = ./.;

                  ${dependencyName} = /path/to/dependency;
                })
```

In fact, this is the same way that the flake depends on your current Haskell
package.

If you depend on a local checkout then you need to pass the `--impure` flag to
the `nix develop` command when you enter the Nix shell:

```ShellSession
$ nix develop --impure
```

… or if you use `direnv` then edit your `.envrc` to use this instead:

```bash
use flake . --impure
```

### Depending on a package from Hackage

Nixpkgs supplies a default version for most packages on Hackage out-of-the-box,
but you can depend on new packages or non-default versions of existing packages
by editing the `packageSourceOverrides` section, like this:

```nix
                (hlib.packageSourceOverrides {
                  ${name} = ./.;

                  # Add your desired package and version here
                  ${hackagePackageName} = ${desiredVversion};
                })
```

For example, if you wanted to depend specifically on version 2.2.3.0 of the
`aeson` package, you'd specify:

```nix
                (hlib.packageSourceOverrides {
                  ${name} = ./.;

                  aeson = "2.2.3.0";
                })
```

Then run:

```ShellSession
$ nix flake lock --update-input all-cabal-hashes
```

### Adding a package from GitHub

You can depend on a package from GitHub instead of Hackage by running this
command:

```ShellSession
$ cabal2nix "${GITHUB_URL}" > "./dependencies/${PACKAGE_NAME}.nix"

$ git add "./dependencies/${PACKAGE_NAME}.nix"
```

For example, if you wanted to depend on `turtle`'s GitHub repository, you'd run:

```ShellSession
$ cabal2nix https://github.com/Gabriella439/turtle > ./dependencies/turtle.nix

$ git add ./dependencies/turtle.nix
```

By default `cabal2nix` will use the latest revision from that package.  If you
want to specify an older revision then use the `--revision` flag:

```ShellSession
$ cabal2nix --revision "${REVISION}" "${GITHUB_URL}" > "./dependencies/${PACKAGE_NAME}.nix"
```

Technically you can use `cabal2nix` and the `./dependencies` directory for
things other than GitHub repositories, but usually for most other types of
dependencies `packageSourceOverrides` will be more ergonomic.

### Overrides

You can tweak a package using the overrides section here:

```nix
              self.lib.composeManyExtensions [
                …

                (hself: hsuper: {
                  # Overrides go here
                })
              ];
```

For example, if you wanted to disable the test suite for the `vector` package,
you'd write:

```nix
                (hself: hsuper: {
                  vector = hlib.dontCheck hsuper.vector;
                })
```

You can find the full list of available functions
[here](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/lib/compose.nix).

## Discussion

### Why `haskellPackagesCustom`?

If you're wondering why the flake assigns the updated package set to a new
`haskellPackagesCustom` attribute:

```nix
        haskellPackagesCustom = self.haskellPackages.override (old: {
```

… instead of updating the `haskellPackages` attribute in place like this:

```nix
        haskellPackages = super.haskellPackages.override (old: {
```

… it's because the latter will trigger an infinite recursion if you use
`packageSourceOverrides` to override any dependency of `cabal2nix` (and
`cabal2nix` has a decent number of dependencies, including `aeson`, `lens` and
`optparse-applicative`).  In particular, this happens because
`packageSourceOverrides` depends on `callCabal2nix`, which in turn depends on
`haskellPackages.cabal2nix-unwrapped`, so if you define `haskellPackages` in
terms of `packageSourceOverrides` you can accidentally trigger an infinite
loop if any of the entries in `packageSourceOverrides` affect
`haskellPackages.cabal2nix-unwrapped`.

The simplest way to avoid this problem is to not override the
`haskellPackages` attribute and to create a new attribute
(`haskellPackagesCustom` in this case).
