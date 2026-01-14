# Changelog

## [0.1.13](https://github.com/andrzej-mag/temporal_sdk/compare/v0.1.12..v0.1.13) - 2026-01-14

### 🚀 Features

- Add [temporal_sdk, task_counter, node/cluster/worker] telemetry events - ([36163ea](https://github.com/andrzej-mag/temporal_sdk/commit/36163eabfccca18027e1876bb7aae0ff3c999ecd))
- Add [temporal_sdk, poller, wait, start] limiter_delay measurement - ([38f9716](https://github.com/andrzej-mag/temporal_sdk/commit/38f9716f814107b40ab0763e63bd76ebf1309abe))
- Improve temporal_sdk_worker:set_limiter_config/5 - ([e5b64a1](https://github.com/andrzej-mag/temporal_sdk/commit/e5b64a15196dd24587484e9bfbdc85b60a002f9a))
- Improve dynamic limiter_config limits handling - ([f60ca56](https://github.com/andrzej-mag/temporal_sdk/commit/f60ca56b355b4697503a57b92dd2f3f28795a9c2))

### 🐛 Bug Fixes

- Fix Elixir cluster and worker is_started/1 wrappers - ([ddfdae9](https://github.com/andrzej-mag/temporal_sdk/commit/ddfdae9b329a0b4f85750340ba1c1b82bc7b0d6b))
- Fix [temporal_sdk, poller, wait, start] telemetry event - ([6fb8f6e](https://github.com/andrzej-mag/temporal_sdk/commit/6fb8f6e0ccfe23a444e8d3de6771bf18f674a38d))
- Fix limited_by [wait, stop] telemetry event measurements - ([4727a30](https://github.com/andrzej-mag/temporal_sdk/commit/4727a308774a6c8e8606e74373b001678256b333))
- Fix temporal_sdk_worker:set_limits/4 - ([df25c8f](https://github.com/andrzej-mag/temporal_sdk/commit/df25c8fc8246fbb69e807ad5bfaf58c9a79fd9ca))

### 🚜 Refactor

- [**breaking**] Rename temporal_sdk_worker:is_alive/1 to is_started/1 - ([9977948](https://github.com/andrzej-mag/temporal_sdk/commit/99779481e4a364d0e7f4c0f27d40d39f3e67572b))
- [**breaking**] Rename temporal_sdk_cluster:is_ready/1 to is_started/1 - ([ddf8acd](https://github.com/andrzej-mag/temporal_sdk/commit/ddf8acd6269f042725a051d2dd66fe5799734085))
- [**breaking**] Rename worker get/set_limits to get/set_limiter_config - ([d72449b](https://github.com/andrzej-mag/temporal_sdk/commit/d72449bfe90506880d6566e4155fec32207a70a3))

### 📚 Documentation

- Improve architecture.md docs - ([01e0815](https://github.com/andrzej-mag/temporal_sdk/commit/01e0815ba6c0f2fec3c4658895d3e04fef54010f))
- Improve temporal_sdk_telemetry docs - ([e9ce3b1](https://github.com/andrzej-mag/temporal_sdk/commit/e9ce3b10a26be494ad7aa859267ed50c44bd24bc))
- Improve temporal_sdk_limiter docs - ([d213588](https://github.com/andrzej-mag/temporal_sdk/commit/d213588f0e6d06a39c2ce18d69103c0ef87f08bb))
- Improve temporal_sdk_node docs - ([f4b92e8](https://github.com/andrzej-mag/temporal_sdk/commit/f4b92e8369bf3c890de51964548dac57f4a072a5))
- Improve temporal_sdk_telemetry docs - ([399df8c](https://github.com/andrzej-mag/temporal_sdk/commit/399df8ce2ee20f86276dc3e31ffefd90eabf3641))
- Improve rate limiter docs - ([b4d258f](https://github.com/andrzej-mag/temporal_sdk/commit/b4d258f1ca5fdcc8ec5e69b3e1e9c0b8927c2508))
- Add temporal_sdk_poller telemetry events docs - ([e5eca11](https://github.com/andrzej-mag/temporal_sdk/commit/e5eca112c3b2b709146fadfc054b95cebb7ed55c))
- Improve rate limiter docs - ([b3a2b86](https://github.com/andrzej-mag/temporal_sdk/commit/b3a2b86df991e3fea845cffbda40ec3a0916fb4f))
- Add temporal_sdk_limiter leaky bucket rate limiter docs - ([7a4c2b3](https://github.com/andrzej-mag/temporal_sdk/commit/7a4c2b3c1e774ef0206d12c8cf656a4b4a886053))
- Improve rate limiter docs - ([c447204](https://github.com/andrzej-mag/temporal_sdk/commit/c447204d7fe90db203712a93c1a2a7a4a1565a18))
- Add temporal_sdk_limiter concurrency and fixed window rate limiters docs - ([036f04e](https://github.com/andrzej-mag/temporal_sdk/commit/036f04e45383d50d50476f1ddf07589d3b911880))
- Improve rate limiter docs - ([aa0154e](https://github.com/andrzej-mag/temporal_sdk/commit/aa0154e260c9717ad0340d75e9d1a56500e3978e))
- Add temporal_sdk_limiter OS rate limiter docs - ([4576c3e](https://github.com/andrzej-mag/temporal_sdk/commit/4576c3ee79d5e281fb3e2439a5278303fe2d19bb))
- Improve rate limiter docs - ([a090103](https://github.com/andrzej-mag/temporal_sdk/commit/a090103d0fd8b285b0a280f5997e930302809b91))
- Add rate limiter docs - ([6be77ae](https://github.com/andrzej-mag/temporal_sdk/commit/6be77ae5c12358720b424273b897d38ff3c47397))
- Fix task worker docs - ([e9bb233](https://github.com/andrzej-mag/temporal_sdk/commit/e9bb233ea393bd89ad2261473a9d7f1965f44b98))
- Add temporal_sdk_worker:set_limiter_config/5 docs - ([cf49565](https://github.com/andrzej-mag/temporal_sdk/commit/cf49565b4121fd61e1b93c523b79b1b08df04f06))
- Add temporal_sdk_worker:set_limiter_config/4 docs - ([60fe201](https://github.com/andrzej-mag/temporal_sdk/commit/60fe20122a3bb65c7ec9ff920b807e37f692736c))
- Add temporal_sdk_worker:get_limiter_config/3 docs - ([60793f9](https://github.com/andrzej-mag/temporal_sdk/commit/60793f9b3dc436a0163a3fad3955f61e175ce1e5))
- Improve SDK node docs - ([586ce5a](https://github.com/andrzej-mag/temporal_sdk/commit/586ce5a426ae6d528c528deb7e2fcf37c1d936e9))
- Improve SDK cluster docs - ([b07e6b0](https://github.com/andrzej-mag/temporal_sdk/commit/b07e6b0f388e9b79a782b115e6f1f32b002f4fce))
- Update architecture.md - ([65eb20d](https://github.com/andrzej-mag/temporal_sdk/commit/65eb20dd85785c25e5c7b52df20447e27e9d7e11))
- Update README.md - ([ecc632e](https://github.com/andrzej-mag/temporal_sdk/commit/ecc632e116778f5a5a2df3e72d99381291e9c465))
- Rename Temporal cluster to SDK cluster - ([18f4d58](https://github.com/andrzej-mag/temporal_sdk/commit/18f4d589f1f796db3589def00db47cd142d282cc))
- Update architecture.md - ([4f30756](https://github.com/andrzej-mag/temporal_sdk/commit/4f30756a967148bbbb8334dd311c3bf8fc218a39))
- Update SDK node docs - ([759cd6d](https://github.com/andrzej-mag/temporal_sdk/commit/759cd6dee62503495317635f81a89f4e4aee5ef2))
- Add basic SDK cluster docs - ([49ece15](https://github.com/andrzej-mag/temporal_sdk/commit/49ece15bed7f8d172780ea370266d30a18534840))
- Add basic task worker docs - ([2e3e6f3](https://github.com/andrzej-mag/temporal_sdk/commit/2e3e6f3cfbd7d82147504ff6b4ea1b1522ec2267))
- Fix architecture.md formatting - ([17d7af5](https://github.com/andrzej-mag/temporal_sdk/commit/17d7af51b5c13a7956030a67c3ff5b625f009103))
- Update SDK node docs - ([d7cea58](https://github.com/andrzej-mag/temporal_sdk/commit/d7cea58b88046b54c4e8961ee578b3d8c2231edb))
- Update architecture.md - ([5668c33](https://github.com/andrzej-mag/temporal_sdk/commit/5668c336f7e279054985184298d413d7f9f6c139))
- Improve SDK node docs - ([cab9489](https://github.com/andrzej-mag/temporal_sdk/commit/cab94899038d9f4c755aae1d3fbad93a739dc117))
- Add SDK node docs - ([7b347fe](https://github.com/andrzej-mag/temporal_sdk/commit/7b347fe4678d7d990d494091ca00c51e840814da))
- Fix telemetry md formatting - ([f1c5849](https://github.com/andrzej-mag/temporal_sdk/commit/f1c5849033b5db7d3e2930a931dfdfc764eb7a88))
- Add telemetry node events docs - ([0feff54](https://github.com/andrzej-mag/temporal_sdk/commit/0feff54f54bd4447dda061f6809b4fc6bf9c9d00))

### ⚙️ Miscellaneous

- Fix rename telemetry Measurement to Measurements - ([ee616bb](https://github.com/andrzej-mag/temporal_sdk/commit/ee616bb05939a133cb2258101a991d882fbb925d))
- Rename limiter_config to limiter_limits in opts - ([db7e99e](https://github.com/andrzej-mag/temporal_sdk/commit/db7e99e3c01718fbfd86eec8b474aef96d037ee2))
- Improve dynamic rate limiter limiter_config - ([3ae20ba](https://github.com/andrzej-mag/temporal_sdk/commit/3ae20baf2234d4a0dc571ba48198ad001e2cd950))
- Extend telemetry EV macro - ([91365bd](https://github.com/andrzej-mag/temporal_sdk/commit/91365bd1cd9cadd3ef1495d19b56bfe0786b1729))
- Update AGENTS.md - ([36bb440](https://github.com/andrzej-mag/temporal_sdk/commit/36bb440520e0ac5ff6caf3478e6cecb8db3826a5))

## [0.1.12](https://github.com/andrzej-mag/temporal_sdk/compare/v0.1.11..v0.1.12) - 2025-12-17

### 🚀 Features

- [**breaking**] Improve SDK telemetry - ([e41b83e](https://github.com/andrzej-mag/temporal_sdk/commit/e41b83e535c38d5d3ab98177e49c8c23f64cc7da))
- Improve cluster sup telemetry - ([37e1cee](https://github.com/andrzej-mag/temporal_sdk/commit/37e1cee1da06df38e4ea4bfcbbd6f04f3645bd8f))

### 🐛 Bug Fixes

- Error handling in node sup - ([a4fbd6e](https://github.com/andrzej-mag/temporal_sdk/commit/a4fbd6ed2fe3a23adff1e793c06f3ed7df0d0af4))

### 🚜 Refactor

- Rename [worker, terminate] to [worker, stop] - ([d2d37d2](https://github.com/andrzej-mag/temporal_sdk/commit/d2d37d234836195e0c06d0b1a52b313274e07af2))
- Rename SDK node scope Partitions to Shards - ([988bc9d](https://github.com/andrzej-mag/temporal_sdk/commit/988bc9d1284bd2157631a17e78dfce284fa3cc49))
- [**breaking**] Rename temporal_sdk_cluster:is_alive/1 to is_ready - ([6533298](https://github.com/andrzej-mag/temporal_sdk/commit/6533298ba961e1e71529c741148b0aa41d1dcd38))
- Improve node supervisor - ([69c4350](https://github.com/andrzej-mag/temporal_sdk/commit/69c43509ff2fcd037cdbe5f450d3b0d135700a8e))

### 📚 Documentation

- Improve Quick Start example - ([6ab2a7a](https://github.com/andrzej-mag/temporal_sdk/commit/6ab2a7a3024c282b6913ffb9d910b28ffb26fb21))
- Add SDK node type docs - ([caf128a](https://github.com/andrzej-mag/temporal_sdk/commit/caf128ae7ab29eb05abb8a6197d82356abab0a73))
- Improve architecture.md - ([8fd324d](https://github.com/andrzej-mag/temporal_sdk/commit/8fd324d85dcd8c32c3b7bf8c19fdc5a8a2df1190))
- Add architecture.md - ([b4ecca4](https://github.com/andrzej-mag/temporal_sdk/commit/b4ecca4005fbefb264a05e567e93941d0b7e140a))
- Improve README.md - ([e96e6f4](https://github.com/andrzej-mag/temporal_sdk/commit/e96e6f4cc0a18e91dce6f27b2343cafc3a8c8741))

### ⚙️ Miscellaneous

- Add AGENTS.md - ([d5c2a95](https://github.com/andrzej-mag/temporal_sdk/commit/d5c2a950ec188f895d386731eee975933e730303))

## [0.1.11](https://github.com/andrzej-mag/temporal_sdk/compare/v0.1.1..v0.1.11) - 2025-11-26

### 🐛 Bug Fixes

- Fix hex package config - ([3ac4ecb](https://github.com/andrzej-mag/temporal_sdk/commit/3ac4ecb966991a79844e9b1685ce71aa271211c2))

## [0.1.1](https://github.com/andrzej-mag/temporal_sdk/compare/v0.1.0..v0.1.1) - 2025-11-26

### 🚀 Features

- Additional Elixir wrapper modules - ([f37d50e](https://github.com/andrzej-mag/temporal_sdk/commit/f37d50e1f548544dcbd214ec8860d50632323103))
- Support for Elixir - ([afa1049](https://github.com/andrzej-mag/temporal_sdk/commit/afa1049659051ca8346f9093c18f749b15c5390d))

### 📚 Documentation

- Update README - ([04f0aa1](https://github.com/andrzej-mag/temporal_sdk/commit/04f0aa137ec81b34259d7b9622867f419ccb2d4c))
- Remove redundant Requirements - ([7e14c92](https://github.com/andrzej-mag/temporal_sdk/commit/7e14c92cc90e038e6a208a9bcff2f05b644ffea2))
- Add Requirements section - ([fe31fce](https://github.com/andrzej-mag/temporal_sdk/commit/fe31fce3f3ad54eabbd92572eaad6eb3baf4128d))
- Update README - ([97f78bc](https://github.com/andrzej-mag/temporal_sdk/commit/97f78bcb7e46952b508dc33683d095d576715f23))
- Add guides - ([a98cb8c](https://github.com/andrzej-mag/temporal_sdk/commit/a98cb8c64c8b1e55f7ea4e8b5ce7bbd77c60ed46))
- Fix hello_world_workflow.ex - ([7090d4e](https://github.com/andrzej-mag/temporal_sdk/commit/7090d4e2f44e3daaf4330952650f17ce98110ebb))

### ⚙️ Miscellaneous

- Fix hex_release - ([08ef27e](https://github.com/andrzej-mag/temporal_sdk/commit/08ef27e0e6e92144173c3a5705fb606e771c3e62))
- Add hex_release script - ([d0d67e0](https://github.com/andrzej-mag/temporal_sdk/commit/d0d67e0b821b8fbdaff1953fe4bcb7711c44095c))
- Simplify some md docs paths - ([ec84e71](https://github.com/andrzej-mag/temporal_sdk/commit/ec84e71a9054c841cb9eb17a5a9e872e57eca021))
- Ignore elp E1599 - ([2fcba75](https://github.com/andrzej-mag/temporal_sdk/commit/2fcba75ec71f128434fbf6d9d5889c014a8d517b))
- Separate shared md docs - ([2910481](https://github.com/andrzej-mag/temporal_sdk/commit/2910481ef234d3520505eb9d51eacc3aeeb7361b))
- Refactor SDK modules layout - ([d92a6f0](https://github.com/andrzej-mag/temporal_sdk/commit/d92a6f0779ae12fc44681222a2d776b869d896c3))

## [0.1.0] - 2025-11-06

### 💼 Other

- Fix hexpm license identifier - ([6a8bd32](https://github.com/andrzej-mag/temporal_sdk/commit/6a8bd324f5f6242e21ad9ef83813447dd16f6b2e))
- Update README - ([f4530d9](https://github.com/andrzej-mag/temporal_sdk/commit/f4530d9c987ede05da128f8d83c2be96d3017742))
- Initial commit - ([b4ba58f](https://github.com/andrzej-mag/temporal_sdk/commit/b4ba58f380ac4ee5383e74b8b247bc236e83468b))
