# ==============================================================================
# ITEM DATABASE - ALL GAME ITEMS AND SPAWNING LOGIC
# ==============================================================================
#
# FILE: scripts/loot/item_database.gd
# PURPOSE: Central database for all loot items with weight-based pricing
#
# ITEM CATEGORIES:
# - Scrap (Common, low value, abundant)
# - Components (Uncommon, medium value)
# - Valuables (Rare, high value)
# - Exotic (Epic/Legendary, very high value)
# - Modules (Equipment upgrades)
#
# ==============================================================================

extends Node
class_name ItemDatabase


# ==============================================================================
# CATEGORY ENUM (matches ContainerTypes.ItemCategory)
# ==============================================================================

enum ItemCategory {
	SCRAP = 0,
	COMPONENT = 1,
	VALUABLE = 2,
	MODULE = 3,
	ARTIFACT = 4
}


# ==============================================================================
# ITEM DEFINITIONS - SCRAP (Common, Rarity 0)
# ==============================================================================

const SCRAP_ITEMS = {
	"scrap_metal": {
		"name": "Scrap Metal",
		"description": "Salvaged hull plating and structural debris. Common but useful.",
		"width": 1, "height": 1,
		"base_value": 15,
		"weight": 5.0,
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/scrap_metal.svg"
	},
	"scrap_plastics": {
		"name": "Scrap Plastics",
		"description": "Assorted synthetic polymers. Lightweight and recyclable.",
		"width": 1, "height": 1,
		"base_value": 10,
		"weight": 1.5,
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/scrap_plastics.svg"
	},
	"scrap_electronics": {
		"name": "Scrap Electronics",
		"description": "Broken circuit boards and components. Contains trace metals.",
		"width": 1, "height": 2,
		"base_value": 35,
		"weight": 2.0,
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/scrap_electronics.svg"
	},
	"scrap_mechanical": {
		"name": "Scrap Mechanical",
		"description": "Gears, springs, and mechanical parts. Heavy but valuable.",
		"width": 2, "height": 1,
		"base_value": 40,
		"weight": 8.0,
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/scrap_mechanical.svg"
	},
	"wire_bundle": {
		"name": "Wire Bundle",
		"description": "Tangled assortment of cables and wiring. Every ship needs spares.",
		"width": 1, "height": 1,
		"base_value": 18,
		"weight": 2.0,
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/wire_bundle.svg"
	},
	"hull_fragment": {
		"name": "Hull Fragment",
		"description": "Piece of reinforced starship armor. Can be reforged.",
		"width": 2, "height": 1,
		"base_value": 25,
		"weight": 10.0,
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/hull_fragment.svg"
	},
	"corroded_pipe": {
		"name": "Corroded Pipe",
		"description": "Rusty coolant conduit. Some copper value remains.",
		"width": 1, "height": 2,
		"base_value": 20,
		"weight": 4.0,
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/corroded_pipe.svg"
	},
	"broken_lens": {
		"name": "Broken Lens",
		"description": "Cracked optical component. Glass can be recycled.",
		"width": 1, "height": 1,
		"base_value": 12,
		"weight": 0.5,
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/broken_lens.svg"
	}
}


# ==============================================================================
# ITEM DEFINITIONS - COMPONENTS (Uncommon, Rarity 1)
# ==============================================================================

const COMPONENT_ITEMS = {
	"copper_wire": {
		"name": "Copper Wire Bundle",
		"description": "High-quality copper wiring. Essential for repairs.",
		"width": 1, "height": 1,
		"base_value": 60,
		"weight": 3.0,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/copper_wire.svg"
	},
	"data_chip": {
		"name": "Data Chip",
		"description": "Encrypted storage module. May contain valuable intel.",
		"width": 1, "height": 1,
		"base_value": 85,
		"weight": 0.2,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/data_chip.svg"
	},
	"fuel_cell": {
		"name": "Fuel Cell",
		"description": "Compact energy storage unit. Powers small devices.",
		"width": 1, "height": 2,
		"base_value": 120,
		"weight": 4.0,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/fuel_cell.svg"
	},
	"plasma_coil": {
		"name": "Plasma Coil",
		"description": "Magnetic containment unit for plasma engines. Dangerous if cracked.",
		"width": 1, "height": 3,
		"base_value": 150,
		"weight": 6.0,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/plasma_coil.svg"
	},
	"processor_unit": {
		"name": "Processor Unit",
		"description": "Shipboard computer CPU. Still functional.",
		"width": 2, "height": 1,
		"base_value": 110,
		"weight": 1.0,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/processor_unit.svg"
	},
	"oxygen_canister": {
		"name": "Oxygen Canister",
		"description": "Emergency life support supplies. Always in demand.",
		"width": 1, "height": 2,
		"base_value": 95,
		"weight": 3.5,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/oxygen_canister.svg"
	},
	"med_kit": {
		"name": "Med Kit",
		"description": "Standard medical supplies. Bandages, antiseptic, and stimulants.",
		"width": 2, "height": 1,
		"base_value": 100,
		"weight": 2.0,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/med_kit.svg"
	},
	"coolant_tube": {
		"name": "Coolant Tube",
		"description": "Temperature regulation component. Keeps reactors stable.",
		"width": 1, "height": 2,
		"base_value": 80,
		"weight": 2.5,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/coolant_tube.svg"
	},
	"nav_beacon": {
		"name": "Navigation Beacon",
		"description": "Portable location transmitter. Useful for marking sites.",
		"width": 1, "height": 1,
		"base_value": 70,
		"weight": 1.5,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/nav_beacon.svg"
	}
}


# ==============================================================================
# ITEM DEFINITIONS - VALUABLES (Rare, Rarity 2)
# ==============================================================================

const VALUABLE_ITEMS = {
	"gold_bar": {
		"name": "Gold Bar",
		"description": "Pure gold ingot. Universal currency across systems.",
		"width": 2, "height": 1,
		"base_value": 500,
		"weight": 12.0,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/gold_bar.svg"
	},
	"rare_alloy": {
		"name": "Rare Alloy Crystal",
		"description": "Exotic crystalline metal. Used in advanced fabrication.",
		"width": 1, "height": 2,
		"base_value": 350,
		"weight": 2.5,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/rare_alloy.svg"
	},
	"weapon_core": {
		"name": "Weapon Core",
		"description": "Power source for military-grade armaments. Heavily regulated.",
		"width": 2, "height": 2,
		"base_value": 400,
		"weight": 8.0,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/weapon_core.svg"
	},
	"nav_computer": {
		"name": "Navigation Computer",
		"description": "Advanced star mapping system. Contains jump coordinates.",
		"width": 2, "height": 2,
		"base_value": 450,
		"weight": 5.0,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/nav_computer.svg"
	},
	"fusion_cell": {
		"name": "Fusion Cell",
		"description": "Miniaturized reactor core. Powers capital ship systems.",
		"width": 1, "height": 2,
		"base_value": 380,
		"weight": 6.0,
		"rarity": 2,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/fusion_cell.svg"
	},
	"targeting_array": {
		"name": "Targeting Array",
		"description": "Military precision optics. Illegal in most sectors.",
		"width": 2, "height": 1,
		"base_value": 320,
		"weight": 3.0,
		"rarity": 2,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/targeting_array.svg"
	},
	"cryo_sample": {
		"name": "Cryo Sample",
		"description": "Frozen biological specimen. Handle with extreme care.",
		"width": 1, "height": 2,
		"base_value": 280,
		"weight": 4.0,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/cryo_sample.svg"
	},
	"encrypted_drive": {
		"name": "Encrypted Drive",
		"description": "Locked data storage. Could contain corporate secrets.",
		"width": 1, "height": 1,
		"base_value": 300,
		"weight": 0.3,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/encrypted_drive.svg"
	}
}


# ==============================================================================
# ITEM DEFINITIONS - EPIC (Rarity 3)
# ==============================================================================

const EPIC_ITEMS = {
	"alien_artifact": {
		"name": "Alien Artifact",
		"description": "Unknown origin. Emits faint energy readings.",
		"width": 2, "height": 2,
		"base_value": 850,
		"weight": 3.0,
		"rarity": 3,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/alien_artifact.svg"
	},
	"quantum_cpu": {
		"name": "Quantum CPU",
		"description": "Next-gen processor using quantum superposition. Priceless.",
		"width": 1, "height": 1,
		"base_value": 650,
		"weight": 0.5,
		"rarity": 3,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/quantum_cpu.svg"
	},
	"stealth_plating": {
		"name": "Stealth Plating",
		"description": "Radar-absorbing hull material. Military prototype.",
		"width": 3, "height": 2,
		"base_value": 950,
		"weight": 15.0,
		"rarity": 3,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/stealth_plating.svg"
	},
	"gravity_dampener": {
		"name": "Gravity Dampener",
		"description": "Manipulates local gravity fields. Experimental tech.",
		"width": 2, "height": 2,
		"base_value": 780,
		"weight": 8.0,
		"rarity": 3,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/gravity_dampener.svg"
	},
	"void_shard": {
		"name": "Void Shard",
		"description": "Fragment of collapsed star matter. Impossibly dense.",
		"width": 1, "height": 1,
		"base_value": 700,
		"weight": 50.0,
		"rarity": 3,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/void_shard.svg"
	},
	"captains_log": {
		"name": "Captain's Log",
		"description": "Personal records of a ship's commander. May contain coordinates.",
		"width": 1, "height": 1,
		"base_value": 600,
		"weight": 0.5,
		"rarity": 3,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/captains_log.svg"
	}
}


# ==============================================================================
# ITEM DEFINITIONS - LEGENDARY (Rarity 4)
# ==============================================================================

const LEGENDARY_ITEMS = {
	"quantum_core": {
		"name": "Quantum Core",
		"description": "Unstable quantum processor. Powers interdimensional drives.",
		"width": 2, "height": 2,
		"base_value": 1800,
		"weight": 5.0,
		"rarity": 4,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/quantum_core.svg"
	},
	"dark_matter_vial": {
		"name": "Dark Matter Vial",
		"description": "Contained dark matter sample. Worth a fortune to scientists.",
		"width": 1, "height": 2,
		"base_value": 2200,
		"weight": 0.1,
		"rarity": 4,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/dark_matter_vial.svg"
	},
	"ancient_relic": {
		"name": "Ancient Relic",
		"description": "Precursor civilization artifact. Thousands of years old.",
		"width": 3, "height": 3,
		"base_value": 3500,
		"weight": 25.0,
		"rarity": 4,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/ancient_relic.svg"
	},
	"prototype_engine": {
		"name": "Prototype Engine",
		"description": "Experimental FTL drive. Only three ever built.",
		"width": 3, "height": 2,
		"base_value": 4000,
		"weight": 40.0,
		"rarity": 4,
		"category": ItemCategory.MODULE,
		"icon": "res://assets/sprites/items/prototype_engine.svg"
	},
	"singularity_gem": {
		"name": "Singularity Gem",
		"description": "Crystallized black hole energy. Radiates impossible light.",
		"width": 2, "height": 2,
		"base_value": 5000,
		"weight": 1.0,
		"rarity": 4,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/singularity_gem.svg"
	}
}


# ==============================================================================
# FACTION-SPECIFIC UNIQUE ITEMS
# ==============================================================================

# CCG (Colonial Cargo Guild) - Trade Focus
const CCG_UNIQUE_ITEMS = {
	"guild_trade_license": {
		"name": "Guild Trade License",
		"description": "Rare authenticated trade documentation. Highly valuable to merchants.",
		"width": 1, "height": 1,
		"base_value": 450,
		"weight": 0.1,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/guild_trade_license.svg",
		"faction_exclusive": "CCG"
	},
	"bulk_cargo_manifest": {
		"name": "Bulk Cargo Manifest",
		"description": "Detailed cargo route logs. Reveals locations of nearby shipments.",
		"width": 1, "height": 2,
		"base_value": 320,
		"weight": 0.2,
		"rarity": 1,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/bulk_cargo_manifest.svg",
		"faction_exclusive": "CCG"
	},
	"premium_fuel_reserves": {
		"name": "Premium Fuel Reserves",
		"description": "High-grade refined ship fuel. Burns cleaner and lasts longer.",
		"width": 2, "height": 1,
		"base_value": 280,
		"weight": 8.0,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/premium_fuel_reserves.svg",
		"faction_exclusive": "CCG"
	},
	"trade_route_data": {
		"name": "Trade Route Data",
		"description": "Encrypted navigation data containing profitable trade routes.",
		"width": 1, "height": 1,
		"base_value": 380,
		"weight": 0.1,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/trade_route_data.svg",
		"faction_exclusive": "CCG"
	},
	"guild_masters_seal": {
		"name": "Guild Master's Seal",
		"description": "Legendary symbol of authority within the CCG. Priceless to collectors.",
		"width": 1, "height": 1,
		"base_value": 2500,
		"weight": 0.5,
		"rarity": 4,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/guild_masters_seal.svg",
		"faction_exclusive": "CCG"
	}
}

# NEX (Nexus Syndicate) - Criminal Focus
const NEX_UNIQUE_ITEMS = {
	"syndicate_cipher": {
		"name": "Syndicate Cipher",
		"description": "Encrypted key that unlocks black market location data.",
		"width": 1, "height": 1,
		"base_value": 420,
		"weight": 0.1,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/syndicate_cipher.svg",
		"faction_exclusive": "NEX"
	},
	"assassination_contract": {
		"name": "Assassination Contract",
		"description": "Illegal hit contract. Extremely valuable on the black market.",
		"width": 1, "height": 2,
		"base_value": 650,
		"weight": 0.1,
		"rarity": 3,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/assassination_contract.svg",
		"faction_exclusive": "NEX"
	},
	"forged_id_chips": {
		"name": "Forged ID Chips",
		"description": "Professional identity forgery kit. Complete with biometric spoofing.",
		"width": 2, "height": 1,
		"base_value": 380,
		"weight": 0.3,
		"rarity": 2,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/forged_id_chips.svg",
		"faction_exclusive": "NEX"
	},
	"syndicate_tribute": {
		"name": "Syndicate Tribute",
		"description": "Cache of protection money collected from various sectors.",
		"width": 2, "height": 2,
		"base_value": 550,
		"weight": 5.0,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/syndicate_tribute.svg",
		"faction_exclusive": "NEX"
	},
	"crime_lords_ledger": {
		"name": "Crime Lord's Ledger",
		"description": "Legendary blackmail material containing secrets of the powerful.",
		"width": 2, "height": 1,
		"base_value": 3200,
		"weight": 0.8,
		"rarity": 4,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/crime_lords_ledger.svg",
		"faction_exclusive": "NEX"
	}
}

# GDF (Galactic Defense Force) - Military Focus
const GDF_UNIQUE_ITEMS = {
	"military_rations_premium": {
		"name": "Military Rations (Premium)",
		"description": "High-quality military food supplies. Nutritious and long-lasting.",
		"width": 2, "height": 1,
		"base_value": 180,
		"weight": 3.0,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/military_rations_premium.svg",
		"faction_exclusive": "GDF"
	},
	"tactical_armor_plating": {
		"name": "Tactical Armor Plating",
		"description": "Advanced composite armor material. Essential for ship upgrades.",
		"width": 3, "height": 2,
		"base_value": 480,
		"weight": 15.0,
		"rarity": 2,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/tactical_armor_plating.svg",
		"faction_exclusive": "GDF"
	},
	"encrypted_orders": {
		"name": "Encrypted Orders",
		"description": "Classified military operation data. Intel agencies pay top credit.",
		"width": 1, "height": 1,
		"base_value": 520,
		"weight": 0.1,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/encrypted_orders.svg",
		"faction_exclusive": "GDF"
	},
	"officers_sidearm": {
		"name": "Officer's Sidearm",
		"description": "Rare military-grade personal weapon. Highly regulated.",
		"width": 2, "height": 1,
		"base_value": 720,
		"weight": 2.0,
		"rarity": 3,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/officers_sidearm.svg",
		"faction_exclusive": "GDF"
	},
	"admirals_medal": {
		"name": "Admiral's Medal",
		"description": "Legendary military honor. Priceless collectible for military historians.",
		"width": 1, "height": 1,
		"base_value": 2800,
		"weight": 0.3,
		"rarity": 4,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/admirals_medal.svg",
		"faction_exclusive": "GDF"
	}
}

# SYN (Synthetix Corp) - Tech Focus
const SYN_UNIQUE_ITEMS = {
	"prototype_chip": {
		"name": "Prototype Chip",
		"description": "Experimental processor technology. Cutting-edge and unstable.",
		"width": 1, "height": 1,
		"base_value": 580,
		"weight": 0.1,
		"rarity": 3,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/prototype_chip.svg",
		"faction_exclusive": "SYN"
	},
	"ai_core_fragment": {
		"name": "AI Core Fragment",
		"description": "Piece of advanced AI neural network. Rare computing component.",
		"width": 1, "height": 2,
		"base_value": 620,
		"weight": 1.0,
		"rarity": 3,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/ai_core_fragment.svg",
		"faction_exclusive": "SYN"
	},
	"nanobot_swarm": {
		"name": "Nanobot Swarm",
		"description": "Medical and repair nanobots in containment. Highly advanced technology.",
		"width": 1, "height": 1,
		"base_value": 680,
		"weight": 0.5,
		"rarity": 3,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/nanobot_swarm.svg",
		"faction_exclusive": "SYN"
	},
	"holographic_projector": {
		"name": "Holographic Projector",
		"description": "Advanced entertainment and presentation technology.",
		"width": 2, "height": 1,
		"base_value": 450,
		"weight": 2.0,
		"rarity": 2,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/holographic_projector.svg",
		"faction_exclusive": "SYN"
	},
	"quantum_processor": {
		"name": "Quantum Processor",
		"description": "Legendary quantum computing core. One of the most advanced chips ever made.",
		"width": 1, "height": 1,
		"base_value": 4200,
		"weight": 0.2,
		"rarity": 4,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/quantum_processor.svg",
		"faction_exclusive": "SYN"
	}
}

# IND (Independent) - Mixed/Salvage Focus
const IND_UNIQUE_ITEMS = {
	"salvage_rights_claim": {
		"name": "Salvage Rights Claim",
		"description": "Legal documentation for salvage operations. Valuable to independent operators.",
		"width": 1, "height": 1,
		"base_value": 280,
		"weight": 0.1,
		"rarity": 1,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/salvage_rights_claim.svg",
		"faction_exclusive": "IND"
	},
	"homemade_repairs": {
		"name": "Homemade Repairs",
		"description": "Jury-rigged ship parts. Not pretty, but they work surprisingly well.",
		"width": 2, "height": 2,
		"base_value": 220,
		"weight": 6.0,
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/homemade_repairs.svg",
		"faction_exclusive": "IND"
	},
	"family_heirloom": {
		"name": "Family Heirloom",
		"description": "Personal item with sentimental value. Worth varies wildly by buyer.",
		"width": 1, "height": 1,
		"base_value": 350,
		"weight": 0.5,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/family_heirloom.svg",
		"faction_exclusive": "IND"
	},
	"prospectors_map": {
		"name": "Prospector's Map",
		"description": "Hand-drawn map pointing to valuable wreck locations.",
		"width": 1, "height": 2,
		"base_value": 420,
		"weight": 0.1,
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/prospectors_map.svg",
		"faction_exclusive": "IND"
	},
	"lucky_charm": {
		"name": "Lucky Charm",
		"description": "Legendary talisman rumored to bring fortune to its owner.",
		"width": 1, "height": 1,
		"base_value": 1800,
		"weight": 0.1,
		"rarity": 4,
		"category": ItemCategory.ARTIFACT,
		"icon": "res://assets/sprites/items/lucky_charm.svg",
		"faction_exclusive": "IND"
	}
}


# ==============================================================================
# ITEM DEFINITIONS - MODULES (Equipment)
# ==============================================================================

const MODULE_ITEMS = {
	"module_engine_booster": {
		"name": "Ion Engine Booster",
		"description": "Increases top speed by 15%. Flight module.",
		"width": 2, "height": 2,
		"base_value": 800,
		"weight": 15.0,
		"rarity": 2,
		"category": ItemCategory.MODULE,
		"icon": "res://assets/sprites/items/module_engine_booster.svg",
		"module_type": "FLIGHT",
		"speed_multiplier": 1.15,
		"tier": 2
	},
	"module_thrusters": {
		"name": "Maneuvering Thrusters",
		"description": "Improves handling and reduces drag. Flight module.",
		"width": 2, "height": 2,
		"base_value": 650,
		"weight": 12.0,
		"rarity": 1,
		"category": ItemCategory.MODULE,
		"icon": "res://assets/sprites/items/module_thrusters.svg",
		"module_type": "FLIGHT",
		"drag_multiplier": 0.85,
		"thrust_bonus": 50.0,
		"tier": 1
	},
	"module_targeting": {
		"name": "Targeting Computer",
		"description": "Increases fire rate by 20%. Combat module.",
		"width": 2, "height": 2,
		"base_value": 900,
		"weight": 8.0,
		"rarity": 2,
		"category": ItemCategory.MODULE,
		"icon": "res://assets/sprites/items/module_targeting.svg",
		"module_type": "COMBAT",
		"fire_rate_multiplier": 1.20,
		"tier": 2
	},
	"module_laser_amp": {
		"name": "Laser Amplifier",
		"description": "Increases laser damage by 25%. Combat module.",
		"width": 2, "height": 1,
		"base_value": 750,
		"weight": 6.0,
		"rarity": 2,
		"category": ItemCategory.MODULE,
		"icon": "res://assets/sprites/items/module_laser_amp.svg",
		"module_type": "COMBAT",
		"damage_multiplier": 1.25,
		"tier": 2
	},
	"module_shield": {
		"name": "Shield Generator",
		"description": "Adds 50 max health and 10% damage reduction. Utility module.",
		"width": 2, "height": 2,
		"base_value": 1000,
		"weight": 20.0,
		"rarity": 3,
		"category": ItemCategory.MODULE,
		"icon": "res://assets/sprites/items/module_shield.svg",
		"module_type": "UTILITY",
		"health_bonus": 50.0,
		"damage_reduction": 0.10,
		"tier": 3
	},
	"module_scanner": {
		"name": "Cargo Scanner",
		"description": "Increases loot value by 15%. Utility module.",
		"width": 2, "height": 2,
		"base_value": 600,
		"weight": 10.0,
		"rarity": 1,
		"category": ItemCategory.MODULE,
		"icon": "res://assets/sprites/items/module_scanner.svg",
		"module_type": "UTILITY",
		"loot_multiplier": 1.15,
		"tier": 1
	}
}


# ==============================================================================
# LOOT TABLES BY TIER/DEPTH
# ==============================================================================

# Tier 0: Near space - mostly scrap, basic components
const LOOT_TABLE_NEAR = {
	"scrap_metal": 20,
	"scrap_plastics": 20,
	"scrap_electronics": 15,
	"scrap_mechanical": 12,
	"wire_bundle": 10,
	"hull_fragment": 8,
	"corroded_pipe": 6,
	"broken_lens": 5,
	"copper_wire": 3,
	"nav_beacon": 1
}

# Tier 1: Middle space - components more common, some valuables
const LOOT_TABLE_MIDDLE = {
	"scrap_metal": 8,
	"scrap_plastics": 8,
	"scrap_electronics": 10,
	"scrap_mechanical": 8,
	"wire_bundle": 6,
	"copper_wire": 12,
	"data_chip": 10,
	"fuel_cell": 8,
	"plasma_coil": 5,
	"processor_unit": 6,
	"oxygen_canister": 5,
	"med_kit": 5,
	"coolant_tube": 4,
	"nav_beacon": 3,
	"module_thrusters": 1,
	"module_scanner": 1
}

# Tier 2: Far space - valuables appear, rare modules
const LOOT_TABLE_FAR = {
	"scrap_electronics": 5,
	"scrap_mechanical": 5,
	"copper_wire": 8,
	"data_chip": 10,
	"fuel_cell": 8,
	"plasma_coil": 6,
	"processor_unit": 6,
	"gold_bar": 8,
	"rare_alloy": 8,
	"weapon_core": 5,
	"nav_computer": 4,
	"fusion_cell": 5,
	"targeting_array": 4,
	"cryo_sample": 3,
	"encrypted_drive": 4,
	"module_thrusters": 3,
	"module_scanner": 2,
	"module_engine_booster": 2,
	"module_laser_amp": 2,
	"module_targeting": 2
}

# Tier 3: Deepest space - epics, legendaries, best modules
const LOOT_TABLE_DEEPEST = {
	"gold_bar": 8,
	"rare_alloy": 8,
	"weapon_core": 6,
	"nav_computer": 5,
	"fusion_cell": 6,
	"encrypted_drive": 5,
	"alien_artifact": 8,
	"quantum_cpu": 6,
	"stealth_plating": 4,
	"gravity_dampener": 5,
	"void_shard": 5,
	"captains_log": 4,
	"quantum_core": 3,
	"dark_matter_vial": 3,
	"ancient_relic": 2,
	"prototype_engine": 2,
	"singularity_gem": 1,
	"module_engine_booster": 5,
	"module_laser_amp": 5,
	"module_targeting": 5,
	"module_shield": 4,
	"module_scanner": 3,
	"module_thrusters": 2
}


# ==============================================================================
# ITEM CREATION FUNCTIONS
# ==============================================================================

## Get all item definitions combined
static func get_all_items() -> Dictionary:
	var all_items = {}
	all_items.merge(SCRAP_ITEMS)
	all_items.merge(COMPONENT_ITEMS)
	all_items.merge(VALUABLE_ITEMS)
	all_items.merge(EPIC_ITEMS)
	all_items.merge(LEGENDARY_ITEMS)
	all_items.merge(MODULE_ITEMS)
	all_items.merge(CCG_UNIQUE_ITEMS)
	all_items.merge(NEX_UNIQUE_ITEMS)
	all_items.merge(GDF_UNIQUE_ITEMS)
	all_items.merge(SYN_UNIQUE_ITEMS)
	all_items.merge(IND_UNIQUE_ITEMS)
	return all_items


## Get items by rarity
static func get_items_by_rarity(rarity: int) -> Dictionary:
	var result = {}
	var all_items = get_all_items()
	for item_id in all_items:
		if all_items[item_id].get("rarity", 0) == rarity:
			result[item_id] = all_items[item_id]
	return result


## Roll a random item from a specific rarity pool
static func roll_item_by_rarity(rarity: int) -> Resource:
	var items = get_items_by_rarity(rarity)
	if items.is_empty():
		return create_item("scrap_metal")
	
	var item_ids = items.keys()
	var random_id = item_ids[randi() % item_ids.size()]
	return create_item(random_id)


## Create an ItemData resource from an item ID
static func create_item(item_id: String) -> Resource:
	var all_items = get_all_items()
	
	if not all_items.has(item_id):
		push_error("Unknown item ID: " + item_id)
		return null
	
	var def = all_items[item_id]
	
	# Check if this is a module
	if def.has("module_type"):
		return _create_module(item_id, def)
	else:
		return _create_basic_item(item_id, def)


## Create a basic ItemData
static func _create_basic_item(item_id: String, def: Dictionary) -> ItemData:
	var item = ItemData.new()
	item.id = item_id
	item.name = def.get("name", "Unknown")
	item.description = def.get("description", "")
	item.grid_width = def.get("width", 1)
	item.grid_height = def.get("height", 1)
	item.rarity = def.get("rarity", 0)
	item.category = def.get("category", ItemCategory.SCRAP)
	item.faction_exclusive = def.get("faction_exclusive", "")
	
	# Calculate value based on weight (heavier = more valuable for same rarity)
	var base_value = def.get("base_value", 50)
	var weight = def.get("weight", 1.0)
	# Value bonus for weight: +2% per kg
	item.value = int(base_value * (1.0 + weight * 0.02))
	
	# Search time based on size and rarity
	var size = item.grid_width * item.grid_height
	item.base_search_time = 1.0 + size * 0.3 + item.rarity * 0.5
	
	# Try to load sprite
	var icon_path = def.get("icon", "")
	if icon_path != "":
		# Try loading the resource directly (Godot auto-imports SVGs)
		if ResourceLoader.exists(icon_path):
			item.sprite = load(icon_path)
		else:
			# Print debug info if sprite not found
			print("[ItemDB] Sprite not found: ", icon_path)
	
	return item


## Create a ModuleData
static func _create_module(item_id: String, def: Dictionary) -> ModuleData:
	var module = ModuleData.new()
	module.id = item_id
	module.name = def.get("name", "Unknown Module")
	module.description = def.get("description", "")
	module.grid_width = def.get("width", 2)
	module.grid_height = def.get("height", 2)
	module.rarity = def.get("rarity", 1)
	module.value = def.get("base_value", 500)
	module.module_tier = def.get("tier", 1)
	
	# Set module type
	var type_str = def.get("module_type", "FLIGHT")
	match type_str:
		"FLIGHT": module.module_type = ModuleData.ModuleType.FLIGHT
		"COMBAT": module.module_type = ModuleData.ModuleType.COMBAT
		"UTILITY": module.module_type = ModuleData.ModuleType.UTILITY
	
	# Apply stat bonuses
	module.speed_multiplier = def.get("speed_multiplier", 1.0)
	module.thrust_bonus = def.get("thrust_bonus", 0.0)
	module.drag_multiplier = def.get("drag_multiplier", 1.0)
	module.damage_multiplier = def.get("damage_multiplier", 1.0)
	module.fire_rate_multiplier = def.get("fire_rate_multiplier", 1.0)
	module.projectile_speed_bonus = def.get("projectile_speed_bonus", 0.0)
	module.health_bonus = def.get("health_bonus", 0.0)
	module.damage_reduction = def.get("damage_reduction", 0.0)
	module.loot_multiplier = def.get("loot_multiplier", 1.0)
	
	# Search time
	module.base_search_time = 2.0 + module.module_tier * 0.5
	
	# Try to load sprite
	var icon_path = def.get("icon", "")
	if icon_path != "":
		if ResourceLoader.exists(icon_path):
			module.sprite = load(icon_path)
		else:
			print("[ItemDB] Module sprite not found: ", icon_path)
	
	return module


## Roll a random item from a loot table
static func roll_item_from_table(table: Dictionary) -> Resource:
	var total_weight = 0
	for weight in table.values():
		total_weight += weight
	
	var roll = randi() % total_weight
	var current = 0
	
	for item_id in table:
		current += table[item_id]
		if roll < current:
			return create_item(item_id)
	
	# Fallback
	return create_item("scrap_metal")


## Get loot table for a given tier
static func get_loot_table(tier: int) -> Dictionary:
	match tier:
		0: return LOOT_TABLE_NEAR
		1: return LOOT_TABLE_MIDDLE
		2: return LOOT_TABLE_FAR
		3: return LOOT_TABLE_DEEPEST
		_: return LOOT_TABLE_NEAR


## Roll random loot for a tier
static func roll_loot(tier: int) -> Resource:
	var table = get_loot_table(tier)
	return roll_item_from_table(table)


## Get a list of all item IDs
static func get_all_item_ids() -> Array:
	return get_all_items().keys()


## Get item definition by ID (for display purposes)
static func get_item_definition(item_id: String) -> Dictionary:
	var all_items = get_all_items()
	return all_items.get(item_id, {})


# ==============================================================================
# ADVANCED LOOT GENERATION WITH SHIP/CONTAINER MODIFIERS
# ==============================================================================

## Base rarity weights (used as starting point)
const BASE_RARITY_WEIGHTS = {
	0: 100,  # Common
	1: 60,   # Uncommon
	2: 25,   # Rare
	3: 10,   # Epic
	4: 5     # Legendary
}


## Roll an item considering ship tier and container type modifiers
static func roll_item_advanced(
	ship_tier: int,
	container_type: int,
	category_weights: Dictionary = {}
) -> Resource:
	# Load data classes
	var ShipTypesClass = load("res://scripts/data/ship_types.gd")
	var ContainerTypesClass = load("res://scripts/data/container_types.gd")
	
	# Calculate modified rarity weights
	var modified_weights: Dictionary = {}
	var total_weight: float = 0.0
	
	for rarity in BASE_RARITY_WEIGHTS:
		var weight: float = BASE_RARITY_WEIGHTS[rarity]
		
		# Apply ship tier modifier
		if ShipTypesClass:
			weight *= ShipTypesClass.get_rarity_modifier(ship_tier, rarity)
		
		# Apply container type modifier
		if ContainerTypesClass:
			weight *= ContainerTypesClass.get_rarity_modifier(container_type, rarity)
		
		modified_weights[rarity] = weight
		total_weight += weight
	
	# Roll for rarity
	var roll = randf() * total_weight
	var cumulative: float = 0.0
	var selected_rarity: int = 0
	
	for rarity in modified_weights:
		cumulative += modified_weights[rarity]
		if roll <= cumulative:
			selected_rarity = rarity
			break
	
	# Now roll for item within that rarity, considering category weights
	return _roll_item_with_category(selected_rarity, category_weights)


## Roll item from a specific rarity with category weighting
static func _roll_item_with_category(
	rarity: int,
	category_weights: Dictionary
) -> Resource:
	var items = get_items_by_rarity(rarity)
	if items.is_empty():
		return create_item("scrap_metal")
	
	# If no category weights, just pick randomly
	if category_weights.is_empty():
		var item_ids = items.keys()
		var random_id = item_ids[randi() % item_ids.size()]
		return create_item(random_id)
	
	# Calculate weighted selection based on category
	var weighted_items: Dictionary = {}
	var total_weight: float = 0.0
	
	for item_id in items:
		var item_def = items[item_id]
		var item_category = item_def.get("category", ItemCategory.SCRAP)
		var weight = category_weights.get(item_category, 1.0)
		
		if weight > 0:
			weighted_items[item_id] = weight
			total_weight += weight
	
	# If no valid items, fall back to random
	if weighted_items.is_empty() or total_weight <= 0:
		var item_ids = items.keys()
		var random_id = item_ids[randi() % item_ids.size()]
		return create_item(random_id)
	
	# Roll weighted selection
	var roll = randf() * total_weight
	var cumulative: float = 0.0
	
	for item_id in weighted_items:
		cumulative += weighted_items[item_id]
		if roll <= cumulative:
			return create_item(item_id)
	
	# Fallback
	return create_item(weighted_items.keys()[0])


## Get items by category
static func get_items_by_category(category: int) -> Dictionary:
	var result = {}
	var all_items = get_all_items()
	for item_id in all_items:
		if all_items[item_id].get("category", 0) == category:
			result[item_id] = all_items[item_id]
	return result


## Get items exclusive to a specific faction
static func get_faction_items(faction_code: String) -> Dictionary:
	var result = {}
	var all_items = get_all_items()
	for item_id in all_items:
		var item_faction = all_items[item_id].get("faction_exclusive", "")
		if item_faction == faction_code:
			result[item_id] = all_items[item_id]
	return result


## Get non-faction-specific items (can appear on any ship)
static func get_common_pool_items() -> Dictionary:
	var result = {}
	var all_items = get_all_items()
	for item_id in all_items:
		var item_faction = all_items[item_id].get("faction_exclusive", "")
		if item_faction == "":
			result[item_id] = all_items[item_id]
	return result


## Generate complete loot for a container with faction support
## Returns array of ItemData
static func generate_container_loot_with_faction(
	ship_tier: int,
	container_type: int,
	item_count: int,
	faction_code: String = ""
) -> Array:
	var ContainerTypesClass = load("res://scripts/data/container_types.gd")
	
	# Get category weights from container
	var category_weights: Dictionary = {}
	if ContainerTypesClass:
		var container_data = ContainerTypesClass.get_container(container_type)
		if container_data:
			category_weights = container_data.category_weights
	
	var items: Array = []
	for i in range(item_count):
		var item = null
		
		# 20% chance for faction-specific item if faction is specified
		if faction_code != "" and randf() < 0.2:
			item = _roll_faction_item(faction_code, ship_tier, container_type, category_weights)
		
		# If no faction item rolled, use normal loot generation
		if item == null:
			item = roll_item_advanced(ship_tier, container_type, category_weights)
		
		if item:
			items.append(item)
	
	return items


## Roll a faction-specific item
static func _roll_faction_item(
	faction_code: String,
	ship_tier: int,
	container_type: int,
	category_weights: Dictionary
) -> Resource:
	var faction_items = get_faction_items(faction_code)
	if faction_items.is_empty():
		return null
	
	# Apply ship tier and container type rarity modifiers
	var ShipTypesClass = load("res://scripts/data/ship_types.gd")
	var ContainerTypesClass = load("res://scripts/data/container_types.gd")
	
	var weighted_items: Dictionary = {}
	var total_weight: float = 0.0
	
	for item_id in faction_items:
		var item_def = faction_items[item_id]
		var item_rarity = item_def.get("rarity", 0)
		var item_category = item_def.get("category", ItemCategory.SCRAP)
		
		# Base weight (higher rarity = lower base weight)
		var weight: float = 1.0
		match item_rarity:
			0: weight = 100.0  # Common
			1: weight = 60.0   # Uncommon
			2: weight = 25.0   # Rare
			3: weight = 10.0   # Epic
			4: weight = 5.0    # Legendary
		
		# Apply ship tier modifier
		if ShipTypesClass:
			weight *= ShipTypesClass.get_rarity_modifier(ship_tier, item_rarity)
		
		# Apply container type modifier
		if ContainerTypesClass:
			weight *= ContainerTypesClass.get_rarity_modifier(container_type, item_rarity)
		
		# Apply category weight
		if not category_weights.is_empty():
			weight *= category_weights.get(item_category, 1.0)
		
		if weight > 0:
			weighted_items[item_id] = weight
			total_weight += weight
	
	# If no valid items after weighting, return null
	if weighted_items.is_empty() or total_weight <= 0:
		return null
	
	# Roll weighted selection
	var roll = randf() * total_weight
	var cumulative: float = 0.0
	
	for item_id in weighted_items:
		cumulative += weighted_items[item_id]
		if roll <= cumulative:
			return create_item(item_id)
	
	# Fallback
	return create_item(weighted_items.keys()[0])


## Generate complete loot for a container
## Returns array of ItemData
static func generate_container_loot(
	ship_tier: int,
	container_type: int,
	item_count: int
) -> Array:
	var ContainerTypesClass = load("res://scripts/data/container_types.gd")
	
	# Get category weights from container
	var category_weights: Dictionary = {}
	if ContainerTypesClass:
		var container_data = ContainerTypesClass.get_container(container_type)
		if container_data:
			category_weights = container_data.category_weights
	
	var items: Array = []
	for i in range(item_count):
		var item = roll_item_advanced(ship_tier, container_type, category_weights)
		if item:
			items.append(item)
	
	return items

