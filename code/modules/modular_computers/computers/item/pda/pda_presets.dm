/obj/item/modular_computer/tablet/pda/preset
	starting_components = list( /obj/item/computer_hardware/processor_unit/pda,
								/obj/item/stock_parts/cell/computer/micro,
								/obj/item/computer_hardware/hard_drive/small/pda,
								/obj/item/computer_hardware/network_card,
								/obj/item/computer_hardware/card_slot)

// This is literally the worst possible cheap tablet
/obj/item/modular_computer/tablet/pda/preset/basic
	desc = "A standard issue PDA often given to station personnel."

/obj/item/modular_computer/tablet/pda/preset/chem
	starting_components = list( /obj/item/computer_hardware/processor_unit/pda,
								/obj/item/stock_parts/cell/computer/micro,
								/obj/item/computer_hardware/hard_drive/small/pda,
								/obj/item/computer_hardware/network_card,
								/obj/item/computer_hardware/card_slot,
								/obj/item/computer_hardware/sensorpackage
								)
/obj/item/modular_computer/tablet/pda/preset/chem/Initialize(mapload)
	starting_files |= list(
		new /datum/computer_file/program/chemscan
	)	
	. = ..()

/obj/item/modular_computer/tablet/pda/preset/medical
/obj/item/modular_computer/tablet/pda/preset/medical/Initialize(mapload)
	starting_files |= list(
		new /datum/computer_file/program/crew_monitor
	)	
	. = ..()

/obj/item/modular_computer/tablet/pda/preset/paramed
/obj/item/modular_computer/tablet/pda/preset/paramed/Initialize(mapload)
	starting_files |= list(
		new /datum/computer_file/program/crew_monitor,
		new /datum/computer_file/program/radar/lifeline
	)	
	. = ..()

/obj/item/modular_computer/tablet/pda/preset/engineering
/obj/item/modular_computer/tablet/pda/preset/engineering/Initialize(mapload)
	starting_files |= list(
		new /datum/computer_file/program/alarm_monitor,
		new /datum/computer_file/program/supermatter_monitor,
		new /datum/computer_file/program/nuclear_monitor,
		new /datum/computer_file/program/power_monitor
	)	
	. = ..()

/obj/item/modular_computer/tablet/pda/preset/warden
/obj/item/modular_computer/tablet/pda/preset/warden/Initialize(mapload)
	starting_files |= list(
		new /datum/computer_file/program/secureye,
	)	
	. = ..()

/obj/item/modular_computer/tablet/pda/preset/robo
/obj/item/modular_computer/tablet/pda/preset/robo/Initialize(mapload)
	starting_files |= list(
		new /datum/computer_file/program/robocontrol,
	)	
	. = ..()

/obj/item/modular_computer/tablet/pda/preset/cargo
/obj/item/modular_computer/tablet/pda/preset/cargo/Initialize(mapload)
	starting_files |= list(
		new /datum/computer_file/program/bounty_board,
		new /datum/computer_file/program/budgetorders,
		new /datum/computer_file/program/cargobounty
	)	
	. = ..()

/obj/item/modular_computer/tablet/pda/preset/basic/atmos
	starting_components = list( /obj/item/computer_hardware/processor_unit/pda,
								/obj/item/stock_parts/cell/computer/micro,
								/obj/item/computer_hardware/hard_drive/small/pda,
								/obj/item/computer_hardware/network_card,
								/obj/item/computer_hardware/card_slot,
								/obj/item/computer_hardware/sensorpackage)

/obj/item/modular_computer/tablet/pda/preset/basic/atmos/Initialize(mapload)
	starting_files |= list(
		new /datum/computer_file/program/atmosscan,
		new /datum/computer_file/program/alarm_monitor,
		new /datum/computer_file/program/supermatter_monitor,
		new /datum/computer_file/program/nuclear_monitor
	)	
	. = ..()

/obj/item/modular_computer/tablet/pda/preset/basic/mime
	pen_type = /obj/item/toy/crayon/mime

/obj/item/modular_computer/tablet/pda/preset/basic/fountainpen // QM, Lawyer, Curator, Bartender
	pen_type = /obj/item/pen/fountain

// Honk
/obj/item/modular_computer/tablet/pda/preset/basic/clown
	desc = "A hilarious PDA often given to station pranksters."
	finish_color = "pink"
	pen_type = /obj/item/toy/crayon/rainbow

/obj/item/modular_computer/tablet/pda/preset/basic/clown/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/slippery, 120, NO_SLIP_WHEN_WALKING)

//for inside one of the nukie lockers
/obj/item/modular_computer/tablet/pda/preset/basic/syndicate
	desc = "A standard issue PDA often given to syndicate agents."

/obj/item/modular_computer/tablet/pda/preset/basic/syndicate/Initialize(mapload)
	. = ..()
	obj_flags |= EMAGGED //starts emagged
	starting_files |= list(
		new /datum/computer_file/program/bomberman
	)	
	