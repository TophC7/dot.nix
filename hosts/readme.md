# TODO:

- I dont like the current system for hosts importing their main user
  -  I could rework hostSpecs so its imported since flake and manage it like that?
  - or just rework the users/default and the hosts/core to just work different...
- Fix up how DEs are configured, its not modular at all rn, i need to be able to select the DE from hostSpec and it should be able to change config per user
- decouple /pool from places its not needed, or should be optional
  - some users should not have access to pool or just cant access it cuz not local 
- ssh keys are not setup per user
  - should probably fix