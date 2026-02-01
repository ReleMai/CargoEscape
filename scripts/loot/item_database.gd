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
# ITEM DEFINITIONS - TRADE GOODS (Raw Materials, Processed Goods, Luxury Items)
# ==============================================================================

const TRADE_GOODS_ITEMS = {
	# Raw Materials (Common)
	"iron_ore": {
		"name": "Iron Ore",
		"description": "Raw iron ore chunks. Essential for manufacturing and construction.",
		"width": 2, "height": 1,
		"base_value": 50,
		"black_market_value": 40,
		"weight": 5.0,
		"tags": ["raw", "metal"],
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/iron_ore.svg"
	},
	"copper_wire_spool": {
		"name": "Copper Wire Spool",
		"description": "High-grade copper wiring for electrical systems.",
		"width": 1, "height": 1,
		"base_value": 75,
		"black_market_value": 60,
		"weight": 1.0,
		"tags": ["raw", "electronics"],
		"rarity": 0,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/copper_wire_spool.svg"
	},
	"plastic_polymers": {
		"name": "Plastic Polymers",
		"description": "Industrial-grade plastic resins for fabrication.",
		"width": 1, "height": 2,
		"base_value": 40,
		"black_market_value": 30,
		"weight": 2.0,
		"tags": ["raw", "industrial"],
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/plastic_polymers.svg"
	},
	"water_barrels": {
		"name": "Water Barrels",
		"description": "Purified water supplies. Life's most essential commodity.",
		"width": 2, "height": 2,
		"base_value": 30,
		"black_market_value": 25,
		"weight": 10.0,
		"tags": ["raw", "essential"],
		"rarity": 0,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/water_barrels.svg"
	},
	"fuel_cells_crate": {
		"name": "Fuel Cells Crate",
		"description": "Portable energy cells. Powers everything from tools to ships.",
		"width": 1, "height": 2,
		"base_value": 100,
		"black_market_value": 120,
		"weight": 3.0,
		"tags": ["raw", "fuel", "regulated"],
		"rarity": 0,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/fuel_cells_crate.svg"
	},
	"titanium_ingots": {
		"name": "Titanium Ingots",
		"description": "Refined titanium bars. Lightweight and incredibly strong.",
		"width": 2, "height": 1,
		"base_value": 120,
		"black_market_value": 100,
		"weight": 3.5,
		"tags": ["raw", "metal"],
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/titanium_ingots.svg"
	},
	"raw_textiles": {
		"name": "Raw Textiles",
		"description": "Synthetic fabric rolls for uniforms and ship interiors.",
		"width": 2, "height": 1,
		"base_value": 45,
		"black_market_value": 35,
		"weight": 2.5,
		"tags": ["raw", "industrial"],
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/raw_textiles.svg"
	},
	"chemical_reagents": {
		"name": "Chemical Reagents",
		"description": "Basic industrial chemicals for processing and manufacturing.",
		"width": 1, "height": 2,
		"base_value": 65,
		"black_market_value": 80,
		"weight": 4.0,
		"tags": ["raw", "industrial", "regulated"],
		"rarity": 0,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/chemical_reagents.svg"
	},
	"silicon_wafers": {
		"name": "Silicon Wafers",
		"description": "High-purity silicon sheets for electronics manufacturing.",
		"width": 1, "height": 1,
		"base_value": 90,
		"black_market_value": 75,
		"weight": 0.5,
		"tags": ["raw", "electronics"],
		"rarity": 0,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/silicon_wafers.svg"
	},
	"rubber_compounds": {
		"name": "Rubber Compounds",
		"description": "Synthetic rubber for seals, gaskets, and insulation.",
		"width": 1, "height": 1,
		"base_value": 35,
		"black_market_value": 28,
		"weight": 1.5,
		"tags": ["raw", "industrial"],
		"rarity": 0,
		"category": ItemCategory.SCRAP,
		"icon": "res://assets/sprites/items/rubber_compounds.svg"
	},
	
	# Processed Goods (Uncommon)
	"circuit_boards": {
		"name": "Circuit Boards",
		"description": "Pre-assembled electronic circuit boards ready for integration.",
		"width": 1, "height": 1,
		"base_value": 200,
		"black_market_value": 180,
		"weight": 0.5,
		"tags": ["tech", "electronics"],
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/circuit_boards.svg"
	},
	"medi_gel": {
		"name": "Medi-Gel",
		"description": "Advanced medical gel for rapid wound treatment.",
		"width": 1, "height": 1,
		"base_value": 300,
		"black_market_value": 400,
		"weight": 0.3,
		"tags": ["medical", "regulated"],
		"rarity": 1,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/medi_gel.svg"
	},
	"ship_parts_crate": {
		"name": "Ship Parts Crate",
		"description": "Assorted replacement parts for ship maintenance.",
		"width": 2, "height": 2,
		"base_value": 250,
		"black_market_value": 200,
		"weight": 4.0,
		"tags": ["tech", "mechanical"],
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/ship_parts_crate.svg"
	},
	"ration_packs": {
		"name": "Ration Packs",
		"description": "Long-shelf-life food supplies for extended voyages.",
		"width": 1, "height": 2,
		"base_value": 80,
		"black_market_value": 60,
		"weight": 1.0,
		"tags": ["food", "essential"],
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/ration_packs.svg"
	},
	"power_converters": {
		"name": "Power Converters",
		"description": "Energy regulation units for stabilizing power systems.",
		"width": 1, "height": 2,
		"base_value": 220,
		"black_market_value": 190,
		"weight": 2.5,
		"tags": ["tech", "electronics"],
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/power_converters.svg"
	},
	"hydroponic_supplies": {
		"name": "Hydroponic Supplies",
		"description": "Growing systems and nutrients for onboard agriculture.",
		"width": 2, "height": 1,
		"base_value": 180,
		"black_market_value": 150,
		"weight": 3.0,
		"tags": ["food", "tech"],
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/hydroponic_supplies.svg"
	},
	"armor_plating": {
		"name": "Armor Plating",
		"description": "Reinforced hull plating for ship defense upgrades.",
		"width": 2, "height": 2,
		"base_value": 280,
		"black_market_value": 240,
		"weight": 8.0,
		"tags": ["tech", "mechanical", "military"],
		"rarity": 1,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/armor_plating.svg"
	},
	"sensor_arrays": {
		"name": "Sensor Arrays",
		"description": "Advanced detection systems for navigation and scanning.",
		"width": 1, "height": 2,
		"base_value": 260,
		"black_market_value": 220,
		"weight": 1.5,
		"tags": ["tech", "electronics"],
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/sensor_arrays.svg"
	},
	"life_support_filters": {
		"name": "Life Support Filters",
		"description": "Air and water purification systems for habitats.",
		"width": 1, "height": 1,
		"base_value": 150,
		"black_market_value": 130,
		"weight": 1.2,
		"tags": ["tech", "essential"],
		"rarity": 1,
		"category": ItemCategory.COMPONENT,
		"icon": "res://assets/sprites/items/life_support_filters.svg"
	},
	"ammunition_crates": {
		"name": "Ammunition Crates",
		"description": "Projectile ammunition for ship-mounted weapons.",
		"width": 2, "height": 1,
		"base_value": 200,
		"black_market_value": 280,
		"weight": 5.0,
		"tags": ["military", "regulated"],
		"rarity": 1,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/ammunition_crates.svg"
	},
	
	# Luxury Goods (Rare)
	"vintage_wine": {
		"name": "Vintage Wine",
		"description": "Rare aged wine from Earth's last vineyards. A collector's item.",
		"width": 1, "height": 2,
		"base_value": 500,
		"black_market_value": 600,
		"weight": 2.0,
		"tags": ["luxury", "fragile"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/vintage_wine.svg"
	},
	"rare_spices": {
		"name": "Rare Spices",
		"description": "Exotic spices from distant colonies. Worth their weight in gold.",
		"width": 1, "height": 1,
		"base_value": 800,
		"black_market_value": 700,
		"weight": 0.2,
		"tags": ["luxury", "food"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/rare_spices.svg"
	},
	"art_pieces": {
		"name": "Art Pieces",
		"description": "Priceless artwork from renowned galactic artists.",
		"width": 2, "height": 2,
		"base_value": 1000,
		"black_market_value": 1200,
		"weight": 3.0,
		"tags": ["luxury", "fragile"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/art_pieces.svg"
	},
	"designer_clothing": {
		"name": "Designer Clothing",
		"description": "High-fashion garments from exclusive designers.",
		"width": 1, "height": 2,
		"base_value": 600,
		"black_market_value": 500,
		"weight": 0.5,
		"tags": ["luxury", "fashion"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/designer_clothing.svg"
	},
	"premium_tobacco": {
		"name": "Premium Tobacco",
		"description": "Rare cigars and tobacco from pre-war plantations.",
		"width": 1, "height": 1,
		"base_value": 450,
		"black_market_value": 550,
		"weight": 0.3,
		"tags": ["luxury", "regulated"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/premium_tobacco.svg"
	},
	"exotic_pets": {
		"name": "Exotic Pets",
		"description": "Rare alien creatures kept as luxury companions.",
		"width": 1, "height": 1,
		"base_value": 900,
		"black_market_value": 1100,
		"weight": 1.0,
		"tags": ["luxury", "living", "regulated"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/exotic_pets.svg"
	},
	"jewelry_collection": {
		"name": "Jewelry Collection",
		"description": "Precious gems and metals crafted into exquisite pieces.",
		"width": 1, "height": 1,
		"base_value": 1200,
		"black_market_value": 1000,
		"weight": 0.5,
		"tags": ["luxury", "valuable"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/jewelry_collection.svg"
	},
	"antique_books": {
		"name": "Antique Books",
		"description": "Rare first editions from Old Earth's great authors.",
		"width": 1, "height": 1,
		"base_value": 700,
		"black_market_value": 650,
		"weight": 1.5,
		"tags": ["luxury", "fragile", "culture"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/antique_books.svg"
	},
	"musical_instruments": {
		"name": "Musical Instruments",
		"description": "Handcrafted instruments from master artisans.",
		"width": 2, "height": 2,
		"base_value": 850,
		"black_market_value": 750,
		"weight": 4.0,
		"tags": ["luxury", "fragile", "culture"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/musical_instruments.svg"
	},
	"perfume_collection": {
		"name": "Perfume Collection",
		"description": "Exclusive fragrances from the finest perfumeries.",
		"width": 1, "height": 1,
		"base_value": 550,
		"black_market_value": 620,
		"weight": 0.4,
		"tags": ["luxury", "fragile"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/perfume_collection.svg"
	},
	"holographic_art": {
		"name": "Holographic Art",
		"description": "State-of-the-art holographic displays showing animated masterpieces.",
		"width": 1, "height": 2,
		"base_value": 950,
		"black_market_value": 1100,
		"weight": 2.0,
		"tags": ["luxury", "tech"],
		"rarity": 2,
		"category": ItemCategory.VALUABLE,
		"icon": "res://assets/sprites/items/holographic_art.svg"
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

# Tier 0: Near space - mostly scrap, basic components, raw materials
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
	"nav_beacon": 1,
	# Trade goods - raw materials
	"iron_ore": 10,
	"plastic_polymers": 8,
	"rubber_compounds": 6,
	"raw_textiles": 5,
	"water_barrels": 4
}

# Tier 1: Middle space - components more common, some valuables, processed goods
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
	"module_scanner": 1,
	# Trade goods - raw materials and processed
	"copper_wire_spool": 8,
	"fuel_cells_crate": 7,
	"titanium_ingots": 6,
	"silicon_wafers": 5,
	"chemical_reagents": 4,
	"circuit_boards": 6,
	"ration_packs": 8,
	"power_converters": 5,
	"life_support_filters": 6,
	"hydroponic_supplies": 4
}

# Tier 2: Far space - valuables appear, rare modules, luxury goods
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
	"module_targeting": 2,
	# Trade goods - processed and luxury
	"medi_gel": 6,
	"ship_parts_crate": 7,
	"sensor_arrays": 5,
	"armor_plating": 4,
	"ammunition_crates": 3,
	"vintage_wine": 4,
	"rare_spices": 5,
	"designer_clothing": 3,
	"premium_tobacco": 3,
	"perfume_collection": 2
}

# Tier 3: Deepest space - epics, legendaries, best modules, rare luxuries
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
	"module_thrusters": 2,
	# Trade goods - luxury items
	"art_pieces": 5,
	"exotic_pets": 4,
	"jewelry_collection": 6,
	"antique_books": 3,
	"musical_instruments": 3,
	"holographic_art": 4
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
	all_items.merge(TRADE_GOODS_ITEMS)
	all_items.merge(MODULE_ITEMS)
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
	
	# Calculate value based on weight (heavier = more valuable for same rarity)
	var base_value = def.get("base_value", 50)
	var weight = def.get("weight", 1.0)
	# Value bonus for weight: +2% per kg
	item.value = int(base_value * (1.0 + weight * 0.02))
	
	# Set weight, black market value, and tags
	item.weight = weight
	var black_market_value = def.get("black_market_value", item.value)
	item.black_market_value = black_market_value
	var tags = def.get("tags", [])
	item.tags = tags
	
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

