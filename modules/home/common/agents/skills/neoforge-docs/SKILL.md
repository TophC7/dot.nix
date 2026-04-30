---
name: neoforge-docs
description: "NeoForge 1.21.1 API and modding reference database. Consult this when working in a NeoForge project and you're uncertain about API specifics, method signatures, registration patterns, correct class names, JSON formats, or NeoForge-patched behaviors. Also consult when the user explicitly asks you to check the NeoForge docs. This is not needed for general knowledge you're already confident about -- only when you'd benefit from verifying details against the official documentation."
---

# NeoForge 1.21.1 Reference Database

Authoritative reference for NeoForge 1.21.1 APIs, patterns, and data formats. This is a local copy of the official documentation for version-accurate lookups.

## When to consult

- You're unsure about exact method signatures, class names, or registration patterns for 1.21.1
- You need to verify NeoForge-specific behavior that may differ from vanilla or older Forge versions
- You're writing code that touches NeoForge APIs and want to confirm the correct approach
- The user explicitly asks you to reference the docs

Don't read these files for things you already know confidently. The value is in catching version-specific details (e.g., NeoForge patches `ContainerData` to support full 32-bit ints, unlike vanilla's 16-bit limit).

## Index

Look up the topic you need and read that file. If a task spans multiple topics, read from each relevant section.

### Getting Started
| File | Covers |
|------|--------|
| `references/gettingstarted/index.md` | Workspace setup, prerequisites, building/testing |
| `references/gettingstarted/modfiles.md` | `neoforge.mods.toml`, `pack.mcmeta`, mod config files |
| `references/gettingstarted/structuring.md` | Mod class structure, package layout, `@Mod` annotation |
| `references/gettingstarted/versioning.md` | Version formats, dependency version ranges |

### Core Concepts
| File | Covers |
|------|--------|
| `references/concepts/events.md` | Event bus, `@SubscribeEvent`, mod bus vs game bus |
| `references/concepts/registries.md` | `DeferredRegister`, registry types, registration timing |
| `references/concepts/sides.md` | Client vs server, `LogicalSide`, `@OnlyIn`, dist executor |

### Blocks
| File | Covers |
|------|--------|
| `references/blocks/index.md` | Block registration, `BlockBehaviour.Properties` |
| `references/blocks/states.md` | Blockstates, `BlockState`, properties, state definitions |

### Items
| File | Covers |
|------|--------|
| `references/items/index.md` | Item registration, `Item.Properties`, creative tabs |
| `references/items/datacomponents.md` | Data components, custom components, `DataComponentType` |
| `references/items/interactionpipeline.md` | Use/interact methods, click actions, interaction results |
| `references/items/mobeffects.md` | Mob effects, effect instances, potions |
| `references/items/tools.md` | Tool tiers, `ToolAction`, `DiggerItem`, armor |

### Block Entities
| File | Covers |
|------|--------|
| `references/blockentities/index.md` | `BlockEntity` creation, registration, `BlockEntityType` |
| `references/blockentities/ber.md` | `BlockEntityRenderer`, custom rendering |

### Inventories
| File | Covers |
|------|--------|
| `references/inventories/container.md` | `Container`, `SimpleContainer`, slot management |
| `references/inventories/capabilities.md` | `IItemHandler`, capability system, `BlockCapability` |

### GUI / Menus
| File | Covers |
|------|--------|
| `references/gui/screens.md` | `Screen` class, widgets, rendering, HUD overlays |
| `references/gui/menus.md` | `AbstractContainerMenu`, `MenuType`, slot setup, data sync |

### Data Storage
| File | Covers |
|------|--------|
| `references/datastorage/codecs.md` | `Codec`, `MapCodec`, codec combinators, custom codecs |
| `references/datastorage/nbt.md` | NBT types, `CompoundTag`, reading/writing NBT |
| `references/datastorage/attachments.md` | Data attachments on entities/chunks/levels |
| `references/datastorage/saveddata.md` | `SavedData` for world-level persistent storage |

### Networking
| File | Covers |
|------|--------|
| `references/networking/index.md` | Networking overview, when to use networking |
| `references/networking/payload.md` | `CustomPacketPayload`, registering payloads, sending packets |
| `references/networking/streamcodecs.md` | `StreamCodec`, composite codecs, ByteBuf codecs |
| `references/networking/configuration-tasks.md` | Configuration phase tasks, login packets |
| `references/networking/entities.md` | Entity data sync, spawn packets |

### Resources (Client)
| File | Covers |
|------|--------|
| `references/resources/index.md` | Resource packs vs data packs, `PackType`, resource locations |
| `references/resources/client/i18n.md` | Internationalization, language files, `Component` |
| `references/resources/client/textures.md` | Texture atlases, custom sprites |
| `references/resources/client/sounds.md` | `sounds.json`, `SoundEvent`, playing sounds |
| `references/resources/client/particles.md` | Particle types, particle providers |
| `references/resources/client/models/index.md` | Model JSON format, item/block model basics |
| `references/resources/client/models/bakedmodel.md` | `BakedModel`, model baking pipeline |
| `references/resources/client/models/datagen.md` | Model data generation, `ModelProvider` |
| `references/resources/client/models/modelloaders.md` | Custom model loaders, geometry loaders |

### Resources (Server / Data)
| File | Covers |
|------|--------|
| `references/resources/server/tags.md` | Item/block/fluid tags, tag conventions |
| `references/resources/server/recipes/index.md` | Recipe system, `Recipe`, `RecipeSerializer`, `RecipeType` |
| `references/resources/server/recipes/builtin.md` | Vanilla recipe types (shaped, shapeless, smelting, etc.) |
| `references/resources/server/recipes/ingredients.md` | Ingredient types, custom ingredients |
| `references/resources/server/loottables/index.md` | Loot table structure, loot pools |
| `references/resources/server/loottables/custom.md` | Custom loot table types |
| `references/resources/server/loottables/glm.md` | Global loot modifiers |
| `references/resources/server/loottables/lootconditions.md` | Loot conditions/predicates |
| `references/resources/server/loottables/lootfunctions.md` | Loot functions |
| `references/resources/server/advancements.md` | Custom advancements, criteria triggers |
| `references/resources/server/conditions.md` | Data load conditions (`neoforge:conditions`) |
| `references/resources/server/damagetypes.md` | Damage types, damage sources |
| `references/resources/server/datamaps/index.md` | Data maps system, `DataMapType` |
| `references/resources/server/datamaps/builtin.md` | Built-in data maps (compostables, furnace fuels, etc.) |
| `references/resources/server/enchantments/index.md` | Enchantment system, custom enchantments |
| `references/resources/server/enchantments/builtin.md` | Built-in enchantment effects |

### World Generation
| File | Covers |
|------|--------|
| `references/worldgen/biomemodifier.md` | Biome modifiers, adding features/spawns, JSON and datagen |

### Miscellaneous
| File | Covers |
|------|--------|
| `references/misc/config.md` | `ModConfigSpec`, config types (CLIENT, COMMON, SERVER) |
| `references/misc/keymappings.md` | Key bindings, `KeyMapping`, input handling |
| `references/misc/resourcelocation.md` | `ResourceLocation` format, namespaces |
| `references/misc/gametest.md` | GameTest framework, automated tests |
| `references/misc/debugprofiler.md` | Debug profiler, performance analysis |
| `references/misc/updatechecker.md` | Mod update checker system |

### Advanced
| File | Covers |
|------|--------|
| `references/advanced/accesstransformers.md` | Access Transformers, modifying visibility of Minecraft classes |
| `references/advanced/extensibleenums.md` | Adding entries to vanilla enums |
