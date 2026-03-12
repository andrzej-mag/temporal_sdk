# Changelog

## [0.1.17](https://github.com/andrzej-mag/temporal_sdk/compare/v0.1.16..v0.1.17) - 2026-03-12

### 🐛 Bug Fixes

- Remove obsolete opentelemetry_api_experimental app entry - ([95fb3f8](https://github.com/andrzej-mag/temporal_sdk/commit/95fb3f865c015109d7910a3e2de0bbbf548506e0))

## [0.1.16](https://github.com/andrzej-mag/temporal_sdk/compare/v0.1.15..v0.1.16) - 2026-03-12

### 🚀 Features

- Replace deterministic_check_mod default to temporal_sdk_api_workflow_check_temporal - ([8d3030a](https://github.com/andrzej-mag/temporal_sdk/commit/8d3030a14740952bc0e7fa816770c9a70dc8e233))
- Extend temporal_sdk:replay_task_opts() - ([79e6396](https://github.com/andrzej-mag/temporal_sdk/commit/79e63961e872674c647e68a2459ccffc47271a8d))
- Add temporal_sdk_service:cancel_workflow/3 - ([af2db70](https://github.com/andrzej-mag/temporal_sdk/commit/af2db704607c0f9159927eb73bf66f21eacd44ed))
- [**breaking**] Improve awaitable handling pipeline - ([12a5cb4](https://github.com/andrzej-mag/temporal_sdk/commit/12a5cb41e35267e2e39e7a88e12893d2421d3619))
- Better worker_opts defaults for WF replay functions - ([39c79ab](https://github.com/andrzej-mag/temporal_sdk/commit/39c79abf17433ccd07c26203733e522a71f83b46))
- Improve temporal_sdk:replay_json/3,4 return value type - ([9b1e138](https://github.com/andrzej-mag/temporal_sdk/commit/9b1e138cd64dd2262f8d091d157eb566f0255628))
- Add disable_telemetry option - ([2079422](https://github.com/andrzej-mag/temporal_sdk/commit/2079422b1e53991809d605adff5cd7f88346d916))
- Add temporal_sdk_api_workflow_check_temporal - ([b1f24af](https://github.com/andrzej-mag/temporal_sdk/commit/b1f24af9124f591bb0108edd7ad64dbf017c9528))

### 🐛 Bug Fixes

- Fix EVENT_TYPE_WORKFLOW_PROPERTIES_MODIFIED as commanded - ([f78e610](https://github.com/andrzej-mag/temporal_sdk/commit/f78e610263bf4f6170f886cba3e15d14a11bb318))
- Fix temporal_sdk_workflow awaitable_event typespecs - ([a87f7a6](https://github.com/andrzej-mag/temporal_sdk/commit/a87f7a65ca767f85779f3cf9cf5b3d70f5d31532))

### 📚 Documentation

- Add temporal_sdk_api_workflow_check docs - ([cd0d2d5](https://github.com/andrzej-mag/temporal_sdk/commit/cd0d2d5e7949a0c60533b2f0dd895bc27f0e7c76))
- Fix moduledoc md file reference - ([82f2ea4](https://github.com/andrzej-mag/temporal_sdk/commit/82f2ea457764161dafaa7056480d4c2d5fcdcb6c))

### 🧪 Testing

- Fix activity a_cancel_3_nde1 replay tests - ([0353e24](https://github.com/andrzej-mag/temporal_sdk/commit/0353e242279cdb7e32d3973ee77a7d8424f2fe02))

### ⚙️ Miscellaneous

- Fix elp W0071 - ([0b65b3d](https://github.com/andrzej-mag/temporal_sdk/commit/0b65b3d44a70131fad156176015a22d484fb047b))
- Fix elp W0066 - ([5f4c35b](https://github.com/andrzej-mag/temporal_sdk/commit/5f4c35b9664a006118fa3d486468337d7f8c50f3))
- Remove redundant -doc attr from temporal_sdk_api_workflow_check_* - ([1915237](https://github.com/andrzej-mag/temporal_sdk/commit/19152373522ebb36b12035037fa67ab7347e4cc4))
- Update TODO.md - ([6b58218](https://github.com/andrzej-mag/temporal_sdk/commit/6b582181ff229590fa5032bda346bf4a993b38f9))
- Remove unused opentelemetry_api_experimental dependency - ([27693bf](https://github.com/andrzej-mag/temporal_sdk/commit/27693bf0511821e9aeb3e1a612397b4cfe6f9303))
- Fix elp replay_test incompatible_types in setelement - ([7028ba4](https://github.com/andrzej-mag/temporal_sdk/commit/7028ba42eaf5dddcce3b8a908e1c4b7aa823b53d))
- Add elixirc_options: [warnings_as_errors: true] - ([768571a](https://github.com/andrzej-mag/temporal_sdk/commit/768571a6c874349d899fba8cd4b43d0204ed9a77))
- Update TODO.md - ([18510ef](https://github.com/andrzej-mag/temporal_sdk/commit/18510ef03e9e519c95e87315413a8928d0f56432))

## [0.1.15](https://github.com/andrzej-mag/temporal_sdk/compare/v0.1.14..v0.1.15) - 2026-02-09

### 🚀 Features

- [**breaking**] Improve temporal_sdk_client grpc_opts_longpoll handling - ([e861d94](https://github.com/andrzej-mag/temporal_sdk/commit/e861d94d72aa0146ee0b2b58d771f71bc5381601))
- Add temporal_sdk_cluster virtual cluster docs - ([5ca9d4c](https://github.com/andrzej-mag/temporal_sdk/commit/5ca9d4c12f16d10de584e03e4b14fd1f20596459))
- Add nexus for [temporal_sdk, cluster, stats] telemetry event - ([2c61715](https://github.com/andrzej-mag/temporal_sdk/commit/2c61715bc54831a42169e8c2bd7c6a60d19f9cff))

### 🐛 Bug Fixes

- Fix temporal_sdk_proto service_info typespecs - ([0547921](https://github.com/andrzej-mag/temporal_sdk/commit/05479217fbd1cef6ac299968dfebaf901054388d))
- Fix gRPC long-poll services list - ([9ef9084](https://github.com/andrzej-mag/temporal_sdk/commit/9ef9084df51c7c75b2e8220b98218bb6ed6a697f))
- Erlang-Elixir docs interop plumbing - ([885bbad](https://github.com/andrzej-mag/temporal_sdk/commit/885bbad42e77a0cd0494c23faeb0dabba0b15184))

### 📚 Documentation

- Add temporal_sdk_telemetry gRPC request events docs - ([4d6d876](https://github.com/andrzej-mag/temporal_sdk/commit/4d6d87635f1ae41706bd006a608e7b2496ed914f))
- Add temporal_sdk_telemetry SDK gRPC client events docs - ([4afcbcf](https://github.com/andrzej-mag/temporal_sdk/commit/4afcbcf16bbc348a5be83276b3be177aa8edbf38))
- Add temporal_sdk_api docs - ([974ebc9](https://github.com/andrzej-mag/temporal_sdk/commit/974ebc9313505813a913e25c6c49f250eed3e6bf))
- Improve temporal_sdk_grpc docs - ([02b7008](https://github.com/andrzej-mag/temporal_sdk/commit/02b70081912b4392bd64dbfb457fbe7ac3aaad5a))
- Improve temporal_sdk_cluster docs - ([312f5fa](https://github.com/andrzej-mag/temporal_sdk/commit/312f5fa3745d18e9cc2de3556a0b6cda9c509d2f))
- Improve temporal_sdk_client docs - ([a7acc70](https://github.com/andrzej-mag/temporal_sdk/commit/a7acc700d8917dcfd6fb262cb4186324629f6632))
- Improve module docs ordering - ([107fd15](https://github.com/andrzej-mag/temporal_sdk/commit/107fd155f484b9ccca75d077cf4671a11f208370))
- Add temporal_sdk_grpc docs - ([61da7db](https://github.com/andrzej-mag/temporal_sdk/commit/61da7dbd68120b112ff8ae543845aa1bf7e2b920))
- Improve quick start docs - ([2e52d2e](https://github.com/andrzej-mag/temporal_sdk/commit/2e52d2e555f840d44020acf897d0cc0c28e4ddcc))
- Improve temporal_sdk_client docs - ([611e8f6](https://github.com/andrzej-mag/temporal_sdk/commit/611e8f6df0dbaa924ecb1aac2c1253a803411d63))
- Improve rate limiter docs - ([93d510a](https://github.com/andrzej-mag/temporal_sdk/commit/93d510a26cde8f4f31db989cf7f6b34469bdb65c))
- Fix missing temporal_sdk_proto_service_* docs - ([1fbf9b3](https://github.com/andrzej-mag/temporal_sdk/commit/1fbf9b301b236a195a0961868ec92f270cd451c1))
- Improve Elixir/Erlang module docs layout - ([5270483](https://github.com/andrzej-mag/temporal_sdk/commit/527048331b67472e1c4fa911697acf5eb8ac28ed))
- Add temporal_sdk_client docs - ([eabc91a](https://github.com/andrzej-mag/temporal_sdk/commit/eabc91a84f47becacc51d89ea9fe2fdb9815f9a4))
- Improve temporal_sdk_cluster config example docs - ([1b40896](https://github.com/andrzej-mag/temporal_sdk/commit/1b4089645be2d6eb1135de02909b1c2bb019f547))
- Add temporal_sdk_telemetry SDK cluster events docs - ([86b6fa3](https://github.com/andrzej-mag/temporal_sdk/commit/86b6fa3a0b187b4fee7f19c55917d16dbf300dab))
- Update temporal_sdk_node docs - ([8659d23](https://github.com/andrzej-mag/temporal_sdk/commit/8659d23a7296a886dfd2dbc993dd138819307f84))
- Add temporal_sdk_cluster functions docs - ([025002d](https://github.com/andrzej-mag/temporal_sdk/commit/025002d41fd737c8a49d782116fcdad3f4325bf6))
- Improve temporal_sdk_cluster docs - ([3e908fb](https://github.com/andrzej-mag/temporal_sdk/commit/3e908fb4ce85ec074ec108a34bcd74974e72ba87))
- Fix TemporalSdk.Utils docs - ([6b0d673](https://github.com/andrzej-mag/temporal_sdk/commit/6b0d673602fe1e92f3982e387bb772350c77ab4d))
- Update temporal_sdk_cluster docs - ([61efe6a](https://github.com/andrzej-mag/temporal_sdk/commit/61efe6a88770f3d36a167038452098e03fd2d625))

### ⚙️ Miscellaneous

- Update AGENTS.md - ([28cc876](https://github.com/andrzej-mag/temporal_sdk/commit/28cc87661752e6a5ba3290c97ee8e7e5d733a257))
- Remove redundant t:temporal_msg/0 and t:temporal_msg_name/0 - ([d365501](https://github.com/andrzej-mag/temporal_sdk/commit/d3655013e2050cb76383ac189470af3bb1abaea5))
- Bump ex_doc version - ([837c50b](https://github.com/andrzej-mag/temporal_sdk/commit/837c50b5796832deb7e4910bf88013dd701f1333))

## [0.1.14](https://github.com/andrzej-mag/temporal_sdk/compare/v0.1.13..v0.1.14) - 2026-01-16

### 🐛 Bug Fixes

- Elixir @external_resource docs fix - ([49c83fd](https://github.com/andrzej-mag/temporal_sdk/commit/49c83fdc7385592100847b9625bc8dd8d65ec321))

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
