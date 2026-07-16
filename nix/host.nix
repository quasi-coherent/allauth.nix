localFlake:
{ aa, config, ... }:
let
  denInput = localFlake.inputs.den;
  name = config.allauth.name;
in
{
  imports = [
    denInput.flakeModules.default
    ./aspects
    (denInput.namespace "aa" true)
  ];

  den.aspects.${name}.includes = [ aa.allauth ];

  den.hosts.x86_64-linux.${name} = {
    intoAttr = [
      "nixosConfigurations"
      name
    ];
  };
}
