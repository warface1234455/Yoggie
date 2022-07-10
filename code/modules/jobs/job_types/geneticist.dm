/datum/job/geneticist
	title = "Geneticist"
	flag = GENETICIST
	department_head = list("Chief Medical Officer", "Research Director")
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "the chief medical officer and research director"
	selection_color = "#d4ebf2"
	exp_type = EXP_TYPE_CREW
	exp_requirements = 60
	alt_titles = list("DNA Mechanic", "Bioengineer", "Junior Geneticist", "Gene Splicer")

	outfit = /datum/outfit/job/geneticist

	added_access = list(ACCESS_CHEMISTRY, ACCESS_XENOBIOLOGY, ACCESS_ROBOTICS, ACCESS_TECH_STORAGE)
	base_access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_GENETICS, ACCESS_CLONING, ACCESS_MECH_MEDICAL, ACCESS_RESEARCH, ACCESS_MINERAL_STOREROOM)
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_MED

	display_order = JOB_DISPLAY_ORDER_GENETICIST

	changed_maps = list("OmegaStation", "EclipseStation")

/datum/job/geneticist/proc/OmegaStationChanges()
	return TRUE

/datum/job/geneticist/proc/EclipseStationChanges()
	total_positions = 3
	spawn_positions = 3

/datum/outfit/job/geneticist
	name = "Geneticist"
	jobtype = /datum/job/geneticist

	pda_type = /obj/item/pda/geneticist

	ears = /obj/item/radio/headset/headset_medsci
	uniform = /obj/item/clothing/under/rank/geneticist
	uniform_skirt = /obj/item/clothing/under/rank/geneticist
	shoes = /obj/item/clothing/shoes/sneakers/white
	suit =  /obj/item/clothing/suit/toggle/labcoat/genetics
	suit_store =  /obj/item/flashlight/pen
	l_pocket = /obj/item/sequence_scanner

	backpack = /obj/item/storage/backpack/genetics
	satchel = /obj/item/storage/backpack/satchel/gen
	duffelbag = /obj/item/storage/backpack/duffelbag/med

