/obj/structure/fermenting_barrel
	name = "wooden barrel"
	desc = "A large wooden barrel. You can ferment fruits and such inside it, or just use it to hold liquid."
	icon = 'icons/obj/objects.dmi'
	icon_state = "barrel"
	density = TRUE
	anchored = FALSE
	pressure_resistance = 2 * ONE_ATMOSPHERE
	max_integrity = 300
	var/open = FALSE
	var/speed_multiplier = 1 //How fast it distills. Defaults to 100% (1.0). Lower is better.

/obj/structure/fermenting_barrel/Initialize(mapload)
	// Bluespace beakers, but without the portability or efficiency in circuits.
	create_reagents(300, DRAINABLE | AMOUNT_VISIBLE)
	. = ..()

/obj/structure/fermenting_barrel/examine(mob/user)
	. = ..()
	. += span_notice("It is currently [open?"open, letting you pour liquids in.":"closed, letting you draw liquids from the tap."]")

/obj/structure/fermenting_barrel/proc/makeWine(obj/item/reagent_containers/food/snacks/grown/fruit)
	if(fruit.reagents)
		fruit.reagents.trans_to(src, fruit.reagents.total_volume)
	var/amount = fruit.seed.potency / 4
	if(fruit.distill_reagent)
		reagents.add_reagent(fruit.distill_reagent, amount)
	else
		var/data = list()
		data["names"] = list("[initial(fruit.name)]" = 1)
		data["color"] = fruit.filling_color
		data["boozepwr"] = fruit.wine_power
		if(fruit.wine_flavor)
			data["tastes"] = list(fruit.wine_flavor = 1)
		else
			data["tastes"] = list(fruit.tastes[1] = 1)
		reagents.add_reagent(/datum/reagent/consumable/ethanol/fruit_wine, amount, data)
	qdel(fruit)
	playsound(src, 'sound/effects/bubbles.ogg', 50, TRUE)

/obj/structure/fermenting_barrel/attackby(obj/item/I, mob/user, params)
	var/obj/item/reagent_containers/food/snacks/grown/fruit = I
	if(istype(fruit))
		if(!fruit.can_distill)
			to_chat(user, span_warning("You can't distill this into anything..."))
			return TRUE
		else if(!user.transferItemToLoc(I,src))
			to_chat(user, span_warning("[I] is stuck to your hand!"))
			return TRUE
		to_chat(user, span_notice("You place [I] into [src] to start the fermentation process."))
		addtimer(CALLBACK(src, PROC_REF(makeWine), fruit), rand(80, 120) * speed_multiplier)
		return TRUE
	if(I.is_refillable())
		return FALSE
	else
		return ..()

/obj/structure/fermenting_barrel/deconstruct(disassembled = TRUE)
	new /obj/item/stack/sheet/mineral/wood (loc, 30)
	qdel(src)

/obj/structure/fermenting_barrel/attack_hand(mob/user)
	open = !open
	if(open)
		DISABLE_BITFIELD(reagents.flags, DRAINABLE)
		ENABLE_BITFIELD(reagents.flags, REFILLABLE)
		to_chat(user, span_notice("You open [src], letting you fill it."))
	else
		ENABLE_BITFIELD(reagents.flags, DRAINABLE)
		DISABLE_BITFIELD(reagents.flags, REFILLABLE)
		to_chat(user, span_notice("You close [src], letting you draw from its tap."))
	update_appearance(UPDATE_ICON)

/obj/structure/fermenting_barrel/update_icon_state()
	. = ..()
	if(open)
		icon_state = "barrel_open"
	else
		icon_state = "barrel"

/datum/crafting_recipe/fermenting_barrel
	name = "Wooden Barrel"
	result = /obj/structure/fermenting_barrel
	reqs = list(/obj/item/stack/sheet/mineral/wood = 10)
	time = 5 SECONDS
	category = CAT_STRUCTURES
