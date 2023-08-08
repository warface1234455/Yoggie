// Index of each node in the list of nodes the reactor has
#define COOLANT_INPUT_GATE 1
#define MODERATOR_INPUT_GATE 2
#define COOLANT_OUTPUT_GATE 3

#define REACTOR_TEMPERATURE_MINIMUM 400 // Minimum temperature needed to run normally
#define REACTOR_TEMPERATURE_OPERATING 800 //Kelvin
#define REACTOR_TEMPERATURE_CRITICAL 1000 //At this point the entire station is alerted to a meltdown. This may need altering
#define REACTOR_TEMPERATURE_MELTDOWN 1200

#define REACTOR_HEAT_CAPACITY 6000 //How much thermal energy it takes to cool the reactor
#define REACTOR_ROD_HEAT_CAPACITY 400 //How much thermal energy it takes to cool each reactor rod
#define REACTOR_HEAT_EXPONENT 1.5 // The exponent used for the function for K heating
#define REACTOR_HEAT_FACTOR (20 / (REACTOR_HEAT_EXPONENT**2)) //How much heat from K

#define REACTOR_NO_COOLANT_TOLERANCE 5 //How many process()ing ticks the reactor can sustain without coolant before slowly taking damage

#define REACTOR_MODERATOR_DECAY_RATE 0.1 //Don't use up ALL of the moderator, engineers need it to last a full round

#define REACTOR_PRESSURE_OPERATING 6000 //Kilopascals
#define REACTOR_PRESSURE_CRITICAL 10000

#define REACTOR_MAX_CRITICALITY 5 //No more criticality than N for now.
#define REACTOR_CRITICALITY_POWER_FACTOR 3000 // affects criticality from high power

#define REACTOR_MAX_FUEL_RODS 5 //Maximum number of fuel rods that can fit in the reactor

#define REACTOR_POWER_FLAVOURISER 500 //To turn those KWs into something usable
#define REACTOR_PERMEABILITY_FACTOR 500 // How effective permeability-type moderators are
#define REACTOR_CONTROL_FACTOR 250 // How effective control-type moderators are


/// Moderator effects, must be added to the moderator input for them to do anything

// Fuel types: increases power, at the cost of making K harder to control
#define PLASMA_FUEL_POWER 1 // baseline fuel
#define TRITIUM_FUEL_POWER 10 // woah there
#define ANTINOBLIUM_FUEL_POWER 100 // oh god oh fuck

// Power types: makes the fuel have more of an effect
#define OXYGEN_POWER_MOD 1 // baseline power modifier gas, optimal plasma/O2 ratio is 50/50 if you can handle the K increase from the plasma
#define HYDROGEN_POWER_MOD 10 // far superior power moderator gas, if you can handle the rads

// Control types: increases the effectiveness of control rods, makes K easier to control
#define NITROGEN_CONTROL_MOD 1 // good at controlling the reaction, but deadly rads
#define CARBON_CONTROL_MOD 2 // even better control, but even worse rads
#define PLUOXIUM_CONTROL_MOD 3 // best control gas, no rads!

// Cooling types: increases the effectiveness of coolant, exchanges more heat per process
#define BZ_PERMEABILITY_MOD 1 // makes cooling more effective
#define WATER_PERMEABILITY_MOD 2 // even better than BZ
#define NOBLIUM_PERMEABILITY_MOD 10 // best gas for cooling

// Radiation types: increases radiation, lower is better
#define NITROGEN_RAD_MOD 0.04 // mmm radiation
#define CARBON_RAD_MOD 0.08 // even higher
#define HYDROGEN_RAD_MOD 0.12 // getting a bit spicy there
#define TRITIUM_RAD_MOD 0.2 // fuck that's a lot
#define ANTINOBLIUM_RAD_MOD 10 // AAAAAAAAAAAAAAAAAAAA


//Remember kids. If the reactor itself is not physically powered by an APC, it cannot shove coolant in!

//Helper proc to set a new looping ambience, and play it to any mobs already inside of that area.


/obj/machinery/atmospherics/components/trinary/nuclear_reactor
	name = "\improper Advanced Gas-Cooled Nuclear Reactor"
	desc = "A tried and tested design which can output stable power at an acceptably low risk. The moderator can be changed to provide different effects."
	icon = 'icons/obj/machines/reactor.dmi'
	icon_state = "reactor_map"
	pixel_x = -32
	pixel_y = -32
	density = FALSE //It burns you if you're stupid enough to walk over it.
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	light_color = LIGHT_COLOR_CYAN
	dir = 8 //Less headache inducing :))
	startingvolume = 600 // 3x base
	var/id = null //Change me mappers
	//Variables essential to operation
	var/active = FALSE
	var/temperature = T20C //Lose control of this -> Meltdown
	var/vessel_integrity = 400 //How long can the reactor withstand overpressure / meltdown? This gives you a fair chance to react to even a massive pipe fire
	var/pressure = 0 //Lose control of this -> Blowout
	var/K = 0 //Rate of reaction.
	var/desired_k = 0
	var/control_rod_effectiveness = 0.65 //Starts off with a lot of control over K. If you flood this thing with plasma, you lose your ability to control K as easily.
	var/power = 0 //0-100%. A function of the maximum heat you can achieve within operating temperature
	var/power_modifier = 1 //Upgrade me with parts, science! Flat out increase to physical power output when loaded with plasma.
	var/list/fuel_rods = list()
	//Secondary variables.
	var/gas_absorption_effectiveness = 0.5
	var/gas_absorption_constant = 0.5 //We refer to this one as it's set on init, randomized.
	var/minimum_coolant_level = MINIMUM_MOLE_COUNT
	var/next_warning = 0 //To avoid spam.
	var/last_power_produced = 0 //For logging purposes
	var/next_flicker = 0 //Light flicker timer
	var/base_power_modifier = REACTOR_POWER_FLAVOURISER
	var/slagged = FALSE //Is this reactor even usable any more?
	//Console statistics.
	var/last_coolant_temperature = 0
	var/last_output_temperature = 0
	var/last_heat_delta = 0 //For administrative cheating only. Knowing the delta lets you know EXACTLY what to set K at.
	var/no_coolant_ticks = 0	//How many times in succession did we not have enough coolant? Decays twice as fast as it accumulates.
	var/last_user = null
	var/current_desired_k = null
	var/datum/powernet/powernet = null
	var/obj/item/radio/radio

	var/has_hit_emergency = FALSE
	var/evacuation_procedures = FALSE

//Use this in your maps if you want everything to be preset.
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/preset
	id = "default_reactor_for_lazy_mappers"

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/examine(mob/user)
	. = ..()
	if(Adjacent(src, user) || isobserver(user))
		var/percent = vessel_integrity / initial(vessel_integrity) * 100
		var/msg
		if(slagged)
			msg = span_boldwarning("The reactor is destroyed. Its core lies exposed!")
		else
			msg = span_warning("The reactor looks operational.")
		switch(percent)
			if(0 to 10)
				msg = span_boldwarning("[src]'s seals are dangerously warped and you can see cracks all over the reactor vessel!")
			if(10 to 40)
				msg = span_boldwarning("[src]'s seals are heavily warped and cracked!")
			if(40 to 60)
				msg = span_warning("[src]'s seals are holding, but barely. You can see some micro-fractures forming in the reactor vessel.")
			if(60 to 80)
				msg = span_warning("[src]'s seals are in-tact, but slightly worn. There are no visible cracks in the reactor vessel.")
			if(80 to 90)
				msg = span_notice("[src]'s seals are in good shape, and there are no visible cracks in the reactor vessel.")
			if(95 to 100)
				msg = span_notice("[src]'s seals look factory new, and the reactor's in excellent shape.")
		. += msg

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/fuel_rod))
		if(slagged)
			to_chat(user, span_notice("The reactor has been critically damaged"))
			return FALSE
		if(temperature > REACTOR_TEMPERATURE_MINIMUM)
			to_chat(user, span_notice("You cannot insert fuel into [src] with the core temperature above [REACTOR_TEMPERATURE_MINIMUM] kelvin."))
			return FALSE
		if(fuel_rods.len >= REACTOR_MAX_FUEL_RODS)
			to_chat(user, span_warning("[src] is already at maximum fuel load."))
			return FALSE
		to_chat(user, span_notice("You start to insert [W] into [src]..."))
		radiation_pulse(src, temperature)
		if(do_after(user, 5 SECONDS, target=src))
			fuel_rods += W
			W.forceMove(src)
			radiation_pulse(src, temperature) //Wear protective equipment when even breathing near a reactor!
			investigate_log("Rod added to reactor by [key_name(user)] at [AREACOORD(src)]", INVESTIGATE_REACTOR)
		return TRUE
	if(istype(W, /obj/item/sealant))
		if(slagged)
			to_chat(user, span_notice("The reactor has been critically damaged!"))
			return FALSE
		if(temperature > REACTOR_TEMPERATURE_MINIMUM)
			to_chat(user, span_notice("You cannot repair [src] while the core temperature is above [REACTOR_TEMPERATURE_MINIMUM] kelvin."))
			return FALSE
		if(vessel_integrity >= 350)
			to_chat(user, span_notice("[src]'s seals are already in-tact, repairing them further would require a new set of seals."))
			return FALSE
		if(vessel_integrity <= 0.5 * initial(vessel_integrity)) //Heavily damaged.
			to_chat(user, span_notice("[src]'s reactor vessel is cracked and worn, you need to repair the cracks with a welder before you can repair the seals."))
			return FALSE
		if(do_after(user, 5 SECONDS, target=src))
			if(vessel_integrity >= 350)	//They might've stacked doafters
				to_chat(user, span_notice("[src]'s seals are already in-tact, repairing them further would require a new set of seals."))
				return FALSE
			playsound(src, 'sound/effects/spray2.ogg', 50, 1, -6)
			user.visible_message(span_warning("[user] applies sealant to some of [src]'s worn out seals."), span_notice("You apply sealant to some of [src]'s worn out seals."))
			vessel_integrity += 10
			vessel_integrity = clamp(vessel_integrity, 0, initial(vessel_integrity))
		return TRUE
	return ..()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/crowbar_act(mob/living/user, obj/item/I)
	if(slagged)
		to_chat(user, span_warning("The fuel rods have melted into a radioactive lump."))
	var/removal_time = 5 SECONDS
	if(temperature > REACTOR_TEMPERATURE_MINIMUM)
		if(istype(I, /obj/item/jawsoflife)) // Snatch the reactor from the jaws of death!
			removal_time *= 2
		else
			to_chat(user, span_warning("You can't remove fuel rods while the reactor is operating above [REACTOR_TEMPERATURE_MINIMUM] kelvin!"))
			return TRUE
	if(!has_fuel())
		to_chat(user, span_notice("The reactor has no fuel rods!"))
		return TRUE
	var/obj/item/fuel_rod/rod = tgui_input_list(usr, "Select a fuel rod to remove", "Fuel Rods", fuel_rods)
	if(rod && istype(rod) && I.use_tool(src, user, removal_time))
		if(temperature > REACTOR_TEMPERATURE_MINIMUM)
			var/turf/T = get_turf(src)
			T.atmos_spawn_air("water_vapor=[pressure/100];TEMP=[temperature]")
		user.rad_act(rod.fuel_power * 1000)
		fuel_rods.Remove(rod)
		if(!user.put_in_hands(rod))
			rod.forceMove(user.loc)
	return TRUE

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/welder_act(mob/living/user, obj/item/I)
	if(slagged)
		to_chat(user, span_notice("The reactor has been critically damaged"))
		return TRUE
	if(temperature > REACTOR_TEMPERATURE_MINIMUM)
		to_chat(user, span_notice("You can't repair [src] while it is running at above [REACTOR_TEMPERATURE_MINIMUM] kelvin."))
		return TRUE
	if(vessel_integrity > 0.5 * initial(vessel_integrity))
		to_chat(user, span_notice("[src] is free from cracks. Further repairs must be carried out with flexi-seal sealant."))
		return TRUE
	if(I.use_tool(src, user, 0, volume=40))
		if(vessel_integrity > 0.5 * initial(vessel_integrity))
			to_chat(user, span_notice("[src] is free from cracks. Further repairs must be carried out with flexi-seal sealant."))
			return TRUE
		vessel_integrity += 20
		to_chat(user, span_notice("You weld together some of [src]'s cracks. This'll do for now."))
	return TRUE

//Admin procs to mess with the reaction environment.

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/lazy_startup()
	for(var/I=0;I<5;I++)
		fuel_rods += new /obj/item/fuel_rod(src)
	message_admins("Reactor started up by admins in [ADMIN_VERBOSEJMP(src)]")
	start_up()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/deplete()
	for(var/obj/item/fuel_rod/FR in fuel_rods)
		FR.depletion = 100

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/Initialize(mapload)
	. = ..()
	icon_state = "reactor_off"
	gas_absorption_effectiveness = rand(5, 6)/10 //All reactors are slightly different. This will result in you having to figure out what the balance is for K.
	gas_absorption_constant = gas_absorption_effectiveness //And set this up for the rest of the round.

	radio = new(src)
	radio.keyslot = new /obj/item/encryptionkey/headset_eng
	radio.subspace_transmission = TRUE
	radio.use_command = TRUE
	radio.canhear_range = 0
	radio.recalculateChannels()

	STOP_PROCESSING(SSmachines, src) //We'll handle this one ourselves.
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/LateInitialize()
	. = ..()
	connect_to_network()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(isliving(AM) && temperature > T0C)
		var/mob/living/L = AM
		L.adjust_bodytemperature(clamp(temperature, BODYTEMP_COOLING_MAX, BODYTEMP_HEATING_MAX)) //If you're on fire, you heat up!

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/process()
	// Make some power!
	var/turf/T = get_turf(src)
	var/obj/structure/cable/C = T.get_cable_node()
	if(C?.powernet)
		add_avail(last_power_produced)

	// You're overloading the reactor. Give a more subtle warning that power is getting out of control.
	if(power >= 90 && world.time >= next_flicker)
		next_flicker = world.time + 1.5 MINUTES
		for(var/obj/machinery/light/L in GLOB.lights)
			if(prob(25) && L.z == z) //If youre running the reactor cold though, no need to flicker the lights.
				L.flicker()
		investigate_log("Reactor overloading at [power]% power", INVESTIGATE_REACTOR)
	
	// Meltdown this, blowout that, I just wanna grill for god's sake!
	for(var/atom/movable/I in get_turf(src))
		if(isliving(I))
			var/mob/living/L = I
			if(temperature > L.bodytemperature)
				L.adjust_bodytemperature(clamp(temperature, BODYTEMP_COOLING_MAX, BODYTEMP_HEATING_MAX)) //If you're on fire, you heat up!
		if(istype(I, /obj/item/reagent_containers/food) && !istype(I, /obj/item/reagent_containers/food/drinks) && temperature >= REACTOR_TEMPERATURE_MINIMUM)
			playsound(src, pick('sound/machines/fryer/deep_fryer_1.ogg', 'sound/machines/fryer/deep_fryer_2.ogg'), 100, TRUE)
			var/obj/item/reagent_containers/food/grilled_item = I
			if(!(grilled_item.foodtype & FRIED))
				if(prob(100 - power))
					return //To give the illusion that it's actually cooking omegalul.
				SEND_SIGNAL(grilled_item, COMSIG_ITEM_GRILLED, src, INFINITY)
				switch(power)
					if(0 to 39)
						grilled_item.name = "grilled [initial(grilled_item.name)]"
						grilled_item.desc = "[initial(I.desc)] It's been grilled over a nuclear reactor."
					if(40 to 70)
						grilled_item.name = "heavily grilled [initial(grilled_item.name)]"
						grilled_item.desc = "[initial(I.desc)] It's been heavily grilled through the magic of nuclear fission."
					if(70 to 95)
						grilled_item.name = "\improper Three-Mile Nuclear-Grilled [initial(grilled_item.name)]"
						grilled_item.desc = "A [initial(grilled_item.name)]. It's been put on top of a nuclear reactor running at extreme power by some badass engineer."
					if(95 to INFINITY)
						grilled_item.name = "\improper Ultimate Meltdown Grilled [initial(grilled_item.name)]"
						grilled_item.desc = "A [initial(grilled_item.name)]. A grill this perfect is a rare technique only known by a few engineers who know how to perform a 'controlled' meltdown whilst also having the time to throw food on a reactor. I'll bet it tastes amazing."
				grilled_item.foodtype |= FRIED
				grilled_item.add_atom_colour(rgb(103,63,24), FIXED_COLOUR_PRIORITY)

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/process_atmos(delta_time)
	//Let's get our gasses sorted out.
	var/datum/gas_mixture/coolant_input = airs[COOLANT_INPUT_GATE]
	var/datum/gas_mixture/moderator_input = airs[MODERATOR_INPUT_GATE]
	var/datum/gas_mixture/coolant_output = airs[COOLANT_OUTPUT_GATE]

	var/power_produced = 0 // How much power we're producing from the moderator
	var/radioactivity_spice_multiplier = 1 + get_fuel_power() //Some gasses make the reactor a bit spicy.
	var/depletion_modifier = 0.035 //How rapidly do your rods decay
	gas_absorption_effectiveness = gas_absorption_constant
	last_power_produced = 0

	//First up, handle moderators!
	if(moderator_input.total_moles() >= minimum_coolant_level)
		// Fuel types: increases power and K
		var/total_fuel_moles = 0
		total_fuel_moles += moderator_input.get_moles(/datum/gas/plasma) * PLASMA_FUEL_POWER
		total_fuel_moles += moderator_input.get_moles(/datum/gas/tritium) * TRITIUM_FUEL_POWER
		total_fuel_moles += moderator_input.get_moles(/datum/gas/antinoblium) * ANTINOBLIUM_FUEL_POWER

		// Power modifier types: increases fuel effectiveness
		var/power_mod_moles = 0
		power_mod_moles += moderator_input.get_moles(/datum/gas/oxygen) * OXYGEN_POWER_MOD
		power_mod_moles += moderator_input.get_moles(/datum/gas/hydrogen) * HYDROGEN_POWER_MOD

		// Now make some actual power!
		if(total_fuel_moles >= minimum_coolant_level) //You at least need SOME fuel.
			var/fuel_power = max((total_fuel_moles * 10 / moderator_input.total_moles()), 1)
			var/power_modifier = max(power_mod_moles * 10 / moderator_input.total_moles(), 1) //You can never have negative IPM. For now.
			power_produced = max(0,((fuel_power*power_modifier)*moderator_input.total_moles())) / delta_time
			if(active)
				coolant_output.adjust_moles(/datum/gas/pluonium, total_fuel_moles/20) //Shove out pluonium into the air when it's fuelled. You need to filter this off, or you're gonna have a bad time.

		// Control types: increases control of K
		var/total_control_moles = 0
		total_control_moles += moderator_input.get_moles(/datum/gas/nitrogen) * NITROGEN_CONTROL_MOD
		total_control_moles += moderator_input.get_moles(/datum/gas/carbon_dioxide) * CARBON_CONTROL_MOD
		total_control_moles += moderator_input.get_moles(/datum/gas/pluoxium) * PLUOXIUM_CONTROL_MOD
		if(total_control_moles >= minimum_coolant_level)
			var/control_bonus = total_control_moles / REACTOR_CONTROL_FACTOR //1 mol of n2 -> 0.002 bonus control rod effectiveness, if you want a super controlled reaction, you'll have to sacrifice some power.
			control_rod_effectiveness = initial(control_rod_effectiveness) + control_bonus

		// Permeability types: increases cooling efficiency
		var/total_permeability_moles = 0
		total_permeability_moles += moderator_input.get_moles(/datum/gas/bz) * BZ_PERMEABILITY_MOD
		total_permeability_moles += moderator_input.get_moles(/datum/gas/water_vapor) * WATER_PERMEABILITY_MOD
		total_permeability_moles += moderator_input.get_moles(/datum/gas/hypernoblium) * NOBLIUM_PERMEABILITY_MOD
		if(total_permeability_moles >= minimum_coolant_level)
			gas_absorption_effectiveness = clamp(gas_absorption_constant + (total_permeability_moles / REACTOR_PERMEABILITY_FACTOR), 0, 1)

		// Radiation types: increases radiation
		radioactivity_spice_multiplier += moderator_input.get_moles(/datum/gas/nitrogen) * NITROGEN_RAD_MOD //An example setup of 50 moles of n2 (for dealing with spent fuel) leaves us with a radioactivity spice multiplier of 3.
		radioactivity_spice_multiplier += moderator_input.get_moles(/datum/gas/carbon_dioxide) * CARBON_RAD_MOD
		radioactivity_spice_multiplier += moderator_input.get_moles(/datum/gas/hydrogen) * HYDROGEN_RAD_MOD 
		radioactivity_spice_multiplier += moderator_input.get_moles(/datum/gas/tritium) * TRITIUM_RAD_MOD
		radioactivity_spice_multiplier += moderator_input.get_moles(/datum/gas/antinoblium) * ANTINOBLIUM_RAD_MOD

		// Degradation types: degrades the fuel rods
		var/total_degradation_moles = moderator_input.get_moles(/datum/gas/pluonium) //Because it's quite hard to get.
		if(total_degradation_moles >= minimum_coolant_level) //I'll be nice.
			depletion_modifier += total_degradation_moles / 15 //Oops! All depletion. This causes your fuel rods to get SPICY.
			playsound(src, pick('sound/machines/sm/accent/normal/1.ogg','sound/machines/sm/accent/normal/2.ogg','sound/machines/sm/accent/normal/3.ogg','sound/machines/sm/accent/normal/4.ogg','sound/machines/sm/accent/normal/5.ogg'), 100, TRUE)

		//From this point onwards, we clear out the remaining gasses.
		moderator_input.remove_ratio(REACTOR_MODERATOR_DECAY_RATE) //Remove about 10% of the gases
		K += total_fuel_moles / 1000
	else // if there's not enough to do anything, just clear it
		moderator_input.clear()

	var/fuel_power = 0 //So that you can't magically generate K with your control rods.
	if(!has_fuel())  //Reactor must be fuelled and ready to go before we can heat it up.
		K = 0
	else
		for(var/obj/item/fuel_rod/FR in fuel_rods)
			K += FR.fuel_power
			fuel_power += FR.fuel_power
			FR.deplete(depletion_modifier)
		K += power / REACTOR_CRITICALITY_POWER_FACTOR
		radioactivity_spice_multiplier += fuel_power

	// Firstly, find the difference between the two numbers.
	var/difference = abs(K - desired_k)

	// Then, hit as much of that goal with our cooling per tick as we possibly can.
	difference = clamp(difference, 0, control_rod_effectiveness) //And we can't instantly zap the K to what we want, so let's zap as much of it as we can manage....
	if(difference > fuel_power && desired_k > K)
		investigate_log("Reactor does not have enough fuel to get [difference]. We have [fuel_power] fuel power.", INVESTIGATE_REACTOR)
		difference = fuel_power //Again, to stop you being able to run off of 1 fuel rod.

	// If K isn't what we want it to be, let's try to change that
	if(K != desired_k)
		if(desired_k > K)
			K += difference
		else if(desired_k < K)
			K -= difference
		if(last_user && current_desired_k != desired_k) // Tell admins about it if it's done by a player
			current_desired_k = desired_k
			message_admins("Reactor desired criticality set to [desired_k] by [ADMIN_LOOKUPFLW(last_user)] in [ADMIN_VERBOSEJMP(src)]")
			investigate_log("reactor desired criticality set to [desired_k] by [key_name(last_user)] at [AREACOORD(src)]", INVESTIGATE_REACTOR)

	// Now, clamp K and heat up the reactor based on it.
	K = clamp(K, 0, REACTOR_MAX_CRITICALITY)
	var/particle_chance = min(power * K, 1000)
	while(particle_chance >= 100)
		fire_nuclear_particle()
		particle_chance -= 100
	if(prob(particle_chance))
		fire_nuclear_particle()
	if(active && has_fuel())
		temperature += REACTOR_HEAT_FACTOR * delta_time * has_fuel() * ((REACTOR_HEAT_EXPONENT**K) - 1) // heating from K has to be exponential to make higher K more dangerous

	// Cooling time!
	var/input_moles = coolant_input.total_moles() //Firstly. Do we have enough moles of coolant?
	if(input_moles >= minimum_coolant_level)
		last_coolant_temperature = coolant_input.return_temperature()
		//Important thing to remember, once you slot in the fuel rods, this thing will not stop making heat, at least, not unless you can live to be thousands of years old which is when the spent fuel finally depletes fully.
		var/heat_delta = (last_coolant_temperature - temperature) * gas_absorption_effectiveness //Take in the gas as a cooled input, cool the reactor a bit. The optimum, 100% balanced reaction sits at K=1, coolant input temp of 200K / -73 celsius.
		var/coolant_heat_factor = coolant_input.heat_capacity() / (coolant_input.heat_capacity() + REACTOR_HEAT_CAPACITY + (REACTOR_ROD_HEAT_CAPACITY * has_fuel())) //What percent of the total heat capacity is in the coolant
		last_heat_delta = heat_delta
		temperature += heat_delta * coolant_heat_factor
		coolant_input.set_temperature(last_coolant_temperature - (heat_delta * (1 - coolant_heat_factor))) //Heat the coolant output gas that we just had pass through us.
		coolant_output.merge(coolant_input) //And now, shove the input into the output.
		coolant_input.clear() //Clear out anything left in the input gate.
		color = null
		no_coolant_ticks = max(0, no_coolant_ticks-2)	//Needs half as much time to recover the ticks than to acquire them
	else
		if(active && has_fuel())
			no_coolant_ticks++
			if(no_coolant_ticks > REACTOR_NO_COOLANT_TOLERANCE)
				temperature += temperature * delta_time / 500 //This isn't really harmful early game, but when your reactor is up to full power, this can get out of hand quite quickly.
				vessel_integrity -= temperature * delta_time / 200 //Think fast loser.
				color = "[COLOR_RED]"
				investigate_log("Reactor taking damage from the lack of coolant", INVESTIGATE_REACTOR)

	// And finally, set our pressure.
	last_output_temperature = coolant_output.return_temperature()
	pressure = coolant_output.return_pressure()
	power = ((temperature / REACTOR_TEMPERATURE_CRITICAL)**3) * 100

	// Make some power!
	if(power_produced > 0)
		last_power_produced = power_produced
		last_power_produced *= (max(0,power)/100) //Aaaand here comes the cap. Hotter reactor => more power.
		last_power_produced *= base_power_modifier //Finally, we turn it into actual usable numbers.
	
	//Let's check if they're about to die, and let them know.
	handle_alerts(delta_time)
	update_icon()

	// Finally, our beautiful radiation!
	radiation_pulse(src, K*temperature*radioactivity_spice_multiplier*has_fuel()/(REACTOR_MAX_CRITICALITY*REACTOR_MAX_FUEL_RODS))


/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/has_fuel()
	return length(fuel_rods)

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/get_fuel_power()
	var/total_fuel_power = 0
	for(var/obj/item/fuel_rod/rod in fuel_rods)
		total_fuel_power += rod.fuel_power
	return total_fuel_power

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/relay(var/sound, var/message=null, loop = FALSE, channel = null) //Sends a sound + text message to the crew of a ship
	for(var/mob/M in GLOB.player_list)
		if(M.z == z)
			if(!isinspace(M))
				if(sound)
					if(channel) //Doing this forbids overlapping of sounds
						SEND_SOUND(M, sound(sound, repeat = loop, wait = 0, volume = 70, channel = channel))
					else
						SEND_SOUND(M, sound(sound, repeat = loop, wait = 0, volume = 70))
				if(message)
					to_chat(M, message)

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/stop_relay(channel) //Stops all playing sounds for crewmen on N channel.
	for(var/mob/M in GLOB.player_list)
		if(M.z == z)
			M.stop_sound_channel(channel)

//Method to handle sound effects, reactor warnings, all that jazz.
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/handle_alerts(delta_time)
	var/alert = FALSE //If we have an alert condition, we'd best let people know.
	//First alert condition: Overpressurized (the more lethal one), has to be checked first so meltdown doesn't override it
	if(pressure >= REACTOR_PRESSURE_CRITICAL)
		alert = TRUE
		if(!has_hit_emergency)
			has_hit_emergency = TRUE
			radio.talk_into(src, "WARNING!! REACTOR CORE OVERPRESSURIZED!! BLOWOUT IMMINENT!!", RADIO_CHANNEL_ENGINEERING)
			playsound(src, 'sound/machines/reactor_alert_3.ogg', 100, extrarange=100, pressure_affected=FALSE, ignore_walls=TRUE)
			investigate_log("Reactor reaching critical pressure at [pressure] kPa with desired criticality at [desired_k]", INVESTIGATE_REACTOR)
			message_admins("Reactor reaching critical pressure at [ADMIN_VERBOSEJMP(src)]")
		shake_animation(0.5)
		playsound(loc, 'sound/machines/clockcult/steam_whoosh.ogg', 100, TRUE)
		var/turf/T = get_turf(src)
		T.atmos_spawn_air("water_vapor=[pressure/100];TEMP=[temperature]")
		var/pressure_damage = min(pressure/300, initial(vessel_integrity)/180) * delta_time	//You get 60 seconds (if you had full integrity), worst-case. But hey, at least it can't be instantly nuked with a pipe-fire.. though it's still very difficult to save.
		vessel_integrity -= pressure_damage
		if(vessel_integrity <= pressure_damage) //It wouldn't be able to tank another hit.
			investigate_log("Reactor blowout at [pressure] kPa with desired criticality at [desired_k]", INVESTIGATE_REACTOR)
			blowout()
			return
	//Second alert condition: Overheat
	if(temperature >= REACTOR_TEMPERATURE_CRITICAL)
		alert = TRUE
		if(!has_hit_emergency)
			has_hit_emergency = TRUE
			for(var/i in 1 to min((temperature-REACTOR_TEMPERATURE_CRITICAL)/100, 10))
				src.fire_nuclear_particle()
			radio.talk_into(src, "WARNING!! REACTOR CORE OVERHEATING!! NUCLEAR MELTDOWN IMMINENT!!", RADIO_CHANNEL_ENGINEERING)
			playsound(src, 'sound/machines/reactor_alert_1.ogg', 100, extrarange=100, pressure_affected=FALSE, ignore_walls=TRUE)
			investigate_log("Reactor reaching critical temperature at [temperature] kelvin with desired criticality at [desired_k]", INVESTIGATE_REACTOR)
			message_admins("Reactor reaching critical temperature at [ADMIN_VERBOSEJMP(src)]")
		if(temperature >= REACTOR_TEMPERATURE_MELTDOWN)
			var/temp_damage = min(temperature/300, initial(vessel_integrity)/180) * delta_time	//3 minutes to meltdown from full integrity, worst-case.
			vessel_integrity -= temp_damage
			if(vessel_integrity <= temp_damage)
				investigate_log("Reactor melted down at [temperature] kelvin with desired criticality at [desired_k]", INVESTIGATE_REACTOR) //It wouldn't be able to tank another hit.
				meltdown() //Oops! All meltdown
				return
	else if(temperature < 73) //That's as cold as I'm letting you get it, engineering.
		color = COLOR_CYAN
	else
		color = null

	if(!alert) //Congrats! You stopped the meltdown / blowout.
		if(!next_warning)
			return // don't bother if the reactor wasn't in trouble
		stop_relay(CHANNEL_REACTOR_ALERT)
		next_warning = 0 // there's no next warning if the reactor is fine
		set_light(0)
		light_color = LIGHT_COLOR_CYAN
		set_light(10)
		has_hit_emergency = FALSE
		var/msg = "Reactor returning to safe operating parameters."
		if(vessel_integrity <= 350)
			msg += " Maintenance required."
		msg += " Structural integrity: [100*vessel_integrity/initial(vessel_integrity)]%."
		radio.talk_into(src, msg, RADIO_CHANNEL_ENGINEERING)
		if(evacuation_procedures)
			radio.talk_into(src, "Attention: Reactor has been stabilized. Please return to your workplaces.", RADIO_CHANNEL_COMMON)
		evacuation_procedures = FALSE
		return

	if(world.time < next_warning) // we're not ready for another warning yet
		return

	next_warning = world.time + 30 SECONDS //To avoid engis pissing people off when reaaaally trying to stop the meltdown or whatever.
	if(vessel_integrity < initial(vessel_integrity)*0.95)
		radio.talk_into(src, "WARNING: Reactor structural integrity faltering. Integrity: [round(100 * vessel_integrity / initial(vessel_integrity), 0.01)]%", RADIO_CHANNEL_ENGINEERING)

	relay('sound/effects/reactor/alarm.ogg', null, TRUE, channel = CHANNEL_REACTOR_ALERT)
	set_light(0)
	light_color = LIGHT_COLOR_RED
	set_light(10)

	//PANIC
	if(vessel_integrity <= initial(vessel_integrity)/4 && !evacuation_procedures)
		evacuation_procedures = TRUE
		radio.talk_into(src, "Reactor failure imminent. Please remain calm and evacuate the facility immediately.", RADIO_CHANNEL_COMMON)
		playsound(src, 'sound/machines/reactor_alert_3.ogg', 100, extrarange=100, pressure_affected=FALSE, ignore_walls=TRUE)

//Failure condition 1: Meltdown. Achieved by having heat go over tolerances. This is less devastating because it's easier to achieve.
//Results: Engineering becomes unusable and your engine irreparable
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/meltdown()
	set waitfor = FALSE
	SSair.atmos_machinery -= src //Annd we're now just a useless brick.
	slagged = TRUE
	color = null
	update_icon()
	STOP_PROCESSING(SSmachines, src)
	icon_state = "reactor_slagged"
	AddComponent(/datum/component/radioactive, 15000 , src, 0)
	var/obj/effect/landmark/nuclear_waste_spawner/NSW = new /obj/effect/landmark/nuclear_waste_spawner/strong(get_turf(src))
	relay('sound/effects/reactor/meltdown.ogg', "<span class='userdanger'>You hear a horrible metallic hissing.</span>")
	stop_relay(CHANNEL_REACTOR_ALERT)
	NSW.fire() //This will take out engineering for a decent amount of time as they have to clean up the sludge.
	for(var/obj/machinery/power/apc/apc in GLOB.apcs_list)
		if((apc.z == z) && prob(70))
			apc.overload_lighting()
	var/datum/gas_mixture/coolant_input = airs[COOLANT_INPUT_GATE]
	var/datum/gas_mixture/moderator_input = airs[MODERATOR_INPUT_GATE]
	var/datum/gas_mixture/coolant_output = airs[COOLANT_OUTPUT_GATE]
	var/turf/T = get_turf(src)
	coolant_input.set_temperature(temperature*2)
	moderator_input.set_temperature(temperature*2)
	coolant_output.set_temperature(temperature*2)
	T.assume_air(coolant_input)
	T.assume_air(moderator_input)
	T.assume_air(coolant_output)
	explosion(get_turf(src), 0, 5, 10, 20, TRUE, TRUE)

//Failure condition 2: Blowout. Achieved by reactor going over-pressured. This is a round-ender because it requires more fuckery to achieve.
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/blowout()
	explosion(get_turf(src), GLOB.MAX_EX_DEVESTATION_RANGE, GLOB.MAX_EX_HEAVY_RANGE, GLOB.MAX_EX_LIGHT_RANGE, GLOB.MAX_EX_FLASH_RANGE)
	meltdown() //Double kill.
	relay('sound/effects/reactor/explode.ogg')
	SSweather.run_weather("nuclear fallout")
	for(var/X in GLOB.landmarks_list)
		if(istype(X, /obj/effect/landmark/nuclear_waste_spawner))
			var/obj/effect/landmark/nuclear_waste_spawner/WS = X
			if(is_station_level(WS.z)) //Begin the SLUDGING
				WS.range *= 3
				WS.fire()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/update_icon(updates=ALL)
	. = ..()
	icon_state = "reactor_off"
	switch(temperature)
		if(0 to REACTOR_TEMPERATURE_MINIMUM)
			icon_state = "reactor_on"
		if(REACTOR_TEMPERATURE_MINIMUM to REACTOR_TEMPERATURE_OPERATING)
			icon_state = "reactor_hot"
		if(REACTOR_TEMPERATURE_OPERATING to REACTOR_TEMPERATURE_CRITICAL)
			icon_state = "reactor_veryhot"
		if(REACTOR_TEMPERATURE_CRITICAL to REACTOR_TEMPERATURE_MELTDOWN) //Point of no return.
			icon_state = "reactor_overheat"
		if(REACTOR_TEMPERATURE_MELTDOWN to INFINITY)
			icon_state = "reactor_meltdown"
	if(!has_fuel())
		icon_state = "reactor_off"
	if(slagged)
		icon_state = "reactor_slagged"


//Startup, shutdown

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/start_up()
	START_PROCESSING(SSmachines, src)
	desired_k = 1
	active = TRUE
	set_light(10)
	var/startup_sound = pick('sound/effects/reactor/startup.ogg', 'sound/effects/reactor/startup2.ogg')
	playsound(loc, startup_sound, 100)
	if(!powernet)
		connect_to_network()

//Shuts off the fuel rods, ambience, etc. Keep in mind that your temperature may still go up!
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/shut_down()
	STOP_PROCESSING(SSmachines, src)
	set_light(0)
	K = 0
	desired_k = 0
	power = 0
	active = FALSE
	update_icon()

//Controlling the reactor.

/obj/machinery/computer/reactor
	name = "Reactor control console"
	desc = "A computer which monitors and controls a reactor"
	light_color = "#55BA55"
	light_power = 1
	light_range = 3
	icon_state = "oldcomp"
	icon_screen = "oldcomp_broken"
	icon_keyboard = null
	var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor = null
	var/id = "default_reactor_for_lazy_mappers"
	var/next_stat_interval = 0
	var/list/kpaData = list()
	var/list/powerData = list()
	var/list/tempCoreData = list()
	var/list/tempInputData = list()
	var/list/tempOutputData = list()

/obj/machinery/computer/reactor/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/reactor/LateInitialize()
	. = ..()
	link_to_reactor()

/obj/machinery/computer/reactor/process()
	kpaData += (reactor) ? reactor.pressure : 0
	if(kpaData.len > 100) //Only lets you track over a certain timeframe.
		kpaData.Cut(1, 2)
	powerData += (reactor) ? reactor.last_power_produced : 0 //We scale up the figure for a consistent:tm: scale
	if(powerData.len > 100) //Only lets you track over a certain timeframe.
		powerData.Cut(1, 2)
	tempCoreData += (reactor) ? reactor.temperature : 0 //We scale up the figure for a consistent:tm: scale
	if(tempCoreData.len > 100) //Only lets you track over a certain timeframe.
		tempCoreData.Cut(1, 2)
	tempInputData += (reactor) ? reactor.last_coolant_temperature : 0 //We scale up the figure for a consistent:tm: scale
	if(tempInputData.len > 100) //Only lets you track over a certain timeframe.
		tempInputData.Cut(1, 2)
	tempOutputData += (reactor) ? reactor.last_output_temperature : 0 //We scale up the figure for a consistent:tm: scale
	if(tempOutputData.len > 100) //Only lets you track over a certain timeframe.
		tempOutputData.Cut(1, 2)

/obj/machinery/computer/reactor/attack_hand(mob/living/user)
	. = ..()
	ui_interact(user)

/obj/machinery/computer/reactor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ReactorComputer")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/reactor/ui_act(action, params)
	if(..())
		return
	if(!reactor)
		return
	switch(action)
		if("power")
			if(reactor.active)
				if(reactor.K <= 0 && reactor.temperature <= REACTOR_TEMPERATURE_MINIMUM)
					reactor.shut_down()
			else if(reactor.fuel_rods.len)
				reactor.start_up()
				message_admins("Reactor started up by [ADMIN_LOOKUPFLW(usr)] in [ADMIN_VERBOSEJMP(src)]")
				investigate_log("Reactor started by [key_name(usr)] at [AREACOORD(src)]", INVESTIGATE_REACTOR)
		if("input")
			var/input = text2num(params["target"])
			reactor.last_user = usr
			reactor.desired_k = reactor.active ? clamp(input, 0, REACTOR_MAX_CRITICALITY) : 0
		if("eject")
			if(reactor?.temperature > REACTOR_TEMPERATURE_MINIMUM)
				return
			if(reactor?.slagged)
				return
			var/obj/item/fuel_rod/rod = locate(params["rodRef"]) in reactor
			if(!rod)
				return
			playsound(src, pick('sound/effects/reactor/switch.ogg','sound/effects/reactor/switch2.ogg','sound/effects/reactor/switch3.ogg'), 100, FALSE)
			playsound(reactor, 'sound/effects/reactor/crane_1.wav', 100, FALSE)
			rod.forceMove(get_turf(reactor))
			reactor.fuel_rods.Remove(rod)

/obj/machinery/computer/reactor/ui_data(mob/user)
	var/list/data = list()
	data["control_rods"] = 0
	data["k"] = 0
	data["desiredK"] = 0
	if(reactor)
		data["k"] = reactor.K
		data["desiredK"] = reactor.desired_k
		data["control_rods"] = 100 - (reactor.desired_k / REACTOR_MAX_CRITICALITY * 100) //Rod insertion is extrapolated as a function of the percentage of K
		data["powerData"] = powerData
	data["kpaData"] = kpaData
	data["tempCoreData"] = tempCoreData
	data["tempInputData"] = tempInputData
	data["tempOutputData"] = tempOutputData
	data["coreTemp"] = reactor ? round(reactor.temperature) : 0
	data["coolantInput"] = reactor ? round(reactor.last_coolant_temperature) : T20C
	data["coolantOutput"] = reactor ? round(reactor.last_output_temperature) : T20C
	data["power"] = reactor ? reactor.last_power_produced : 0
	data["kpa"] = reactor ? reactor.pressure : 0
	data["active"] = reactor ? reactor.active : FALSE
	data["shutdownTemp"] = REACTOR_TEMPERATURE_MINIMUM
	data["rods"] = list()
	if(reactor)
		for(var/obj/item/fuel_rod/rod in reactor.fuel_rods)
			data["rods"][REF(rod)] = list(list("name" = rod.name, "depletion" = rod.depletion))
	return data

/obj/machinery/computer/reactor/wrench_act(mob/living/user, obj/item/I)
	to_chat(user, span_notice("You start [anchored ? "un" : ""]securing [name]..."))
	if(I.use_tool(src, user, 40, volume=75))
		to_chat(user, span_notice("You [anchored ? "un" : ""]secure [name]."))
		setAnchored(!anchored)
		return TRUE
	return FALSE

/obj/machinery/computer/reactor/proc/link_to_reactor()
	for(var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/asdf in GLOB.machines)
		if(asdf.id && asdf.id == id)
			reactor = asdf
			return TRUE
	return FALSE

#define FREQ_REACTOR_CONTROL 1439.69

//Preset pumps for mappers. You can also set the id tags yourself.
/obj/machinery/atmospherics/components/binary/pump/reactor_input
	id = "reactor_input"
	frequency = FREQ_REACTOR_CONTROL

/obj/machinery/atmospherics/components/binary/pump/reactor_output
	id = "reactor_output"
	frequency = FREQ_REACTOR_CONTROL

/obj/machinery/atmospherics/components/binary/pump/reactor_moderator
	id = "reactor_moderator"
	frequency = FREQ_REACTOR_CONTROL

/obj/machinery/computer/reactor/pump
	name = "Reactor inlet valve computer"
	desc = "A computer which controls valve settings on an advanced gas cooled reactor. Alt click it to remotely set pump pressure."
	icon_screen = "reactor_input"
	id = "reactor_input"
	var/datum/radio_frequency/radio_connection
	var/on = FALSE

/obj/machinery/computer/reactor/pump/AltClick(mob/user)
	. = ..()
	var/newPressure = input(user, "Set new output pressure (kPa)", "Remote pump control", null) as num
	if(!newPressure)
		return
	newPressure = clamp(newPressure, 0, MAX_OUTPUT_PRESSURE) //Number sanitization is not handled in the pumps themselves, only during their ui_act which this doesn't use.
	signal(on, newPressure)

/obj/machinery/computer/reactor/attack_robot(mob/user)
	. = ..()
	attack_hand(user)

/obj/machinery/computer/reactor/attack_ai(mob/user)
	. = ..()
	attack_hand(user)

/obj/machinery/computer/reactor/pump/attack_hand(mob/living/user)
	. = ..()
	if(!is_operational())
		return FALSE
	playsound(loc, pick('sound/effects/reactor/switch.ogg','sound/effects/reactor/switch2.ogg','sound/effects/reactor/switch3.ogg'), 100, FALSE)
	visible_message(span_notice("[src]'s switch flips [on ? "off" : "on"]."))
	on = !on
	signal(on)

/obj/machinery/computer/reactor/pump/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	radio_connection = SSradio.add_object(src, FREQ_REACTOR_CONTROL,filter=RADIO_ATMOSIA)

/obj/machinery/computer/reactor/pump/proc/signal(power, set_output_pressure=null)
	var/datum/signal/signal
	if(!set_output_pressure) //Yes this is stupid, but technically if you pass through "set_output_pressure" onto the signal, it'll always try and set its output pressure and yeahhh...
		signal = new(list(
			"tag" = id,
			"frequency" = FREQ_REACTOR_CONTROL,
			"timestamp" = world.time,
			"power" = power,
			"sigtype" = "command"
		))
	else
		signal = new(list(
			"tag" = id,
			"frequency" = FREQ_REACTOR_CONTROL,
			"timestamp" = world.time,
			"power" = power,
			"set_output_pressure" = set_output_pressure,
			"sigtype" = "command"
		))
	radio_connection.post_signal(src, signal, filter=RADIO_ATMOSIA)

//Preset subtypes for mappers
/obj/machinery/computer/reactor/pump/reactor_input
	name = "Reactor inlet valve computer"
	icon_screen = "reactor_input"
	id = "reactor_input"

/obj/machinery/computer/reactor/pump/reactor_output
	name = "Reactor output valve computer"
	icon_screen = "reactor_output"
	id = "reactor_output"

/obj/machinery/computer/reactor/pump/reactor_moderator
	name = "Reactor moderator valve computer"
	icon_screen = "reactor_moderator"
	id = "reactor_moderator"

//Monitoring program.
/datum/computer_file/program/nuclear_monitor
	filename = "agcnrmonitor"
	filedesc = "Nuclear Reactor Monitoring"
	category = PROGRAM_CATEGORY_ENGI
	ui_header = "smmon_0.gif"
	program_icon_state = "smmon_0"
	extended_desc = "This program connects to specially calibrated sensors to provide information on the status of nuclear reactors."
	requires_ntnet = TRUE
	transfer_access = ACCESS_ENGINE
	program_icon = "radiation" // duh
	//network_destination = "reactor monitoring system" dont need anymore?
	size = 2
	tgui_id = "NtosReactorStats"
	var/active = TRUE //Easy process throttle
	var/next_stat_interval = 0
	var/list/kpaData = list()
	var/list/powerData = list()
	var/list/tempCoreData = list()
	var/list/tempInputData = list()
	var/list/tempOutputData = list()
	var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor //Our reactor.

/datum/computer_file/program/nuclear_monitor/process_tick()
	..()
	if(!reactor || !active)
		return FALSE
	var/stage = 0
	switch(reactor.temperature)
		if(0 to REACTOR_TEMPERATURE_MINIMUM)
			stage = 1
		if(REACTOR_TEMPERATURE_MINIMUM to REACTOR_TEMPERATURE_OPERATING)
			stage = 2
		if(REACTOR_TEMPERATURE_OPERATING to REACTOR_TEMPERATURE_CRITICAL)
			stage = 3
		if(REACTOR_TEMPERATURE_CRITICAL to REACTOR_TEMPERATURE_MELTDOWN)
			stage = 4
		if(REACTOR_TEMPERATURE_MELTDOWN to INFINITY)
			stage = 5
			if(reactor.vessel_integrity <= 100) //Bye bye! GET OUT!
				stage = 6
	ui_header = "smmon_[stage].gif"
	program_icon_state = "smmon_[stage]"
	if(istype(computer))
		computer.update_icon()
	if(world.time >= next_stat_interval)
		next_stat_interval = world.time + 1 SECONDS //You only get a slow tick.
		kpaData += (reactor) ? reactor.pressure : 0
		if(kpaData.len > 100) //Only lets you track over a certain timeframe.
			kpaData.Cut(1, 2)
		powerData += (reactor) ? reactor.last_power_produced : 0 //We scale up the figure for a consistent:tm: scale
		if(powerData.len > 100) //Only lets you track over a certain timeframe.
			powerData.Cut(1, 2)
		tempCoreData += (reactor) ? reactor.temperature : 0 //We scale up the figure for a consistent:tm: scale
		if(tempCoreData.len > 100) //Only lets you track over a certain timeframe.
			tempCoreData.Cut(1, 2)
		tempInputData += (reactor) ? reactor.last_coolant_temperature : 0 //We scale up the figure for a consistent:tm: scale
		if(tempInputData.len > 100) //Only lets you track over a certain timeframe.
			tempInputData.Cut(1, 2)
		tempOutputData += (reactor) ? reactor.last_output_temperature : 0 //We scale up the figure for a consistent:tm: scale
		if(tempOutputData.len > 100) //Only lets you track over a certain timeframe.
			tempOutputData.Cut(1, 2)

/datum/computer_file/program/nuclear_monitor/run_program(mob/living/user)
	. = ..(user)
	//No reactor? Go find one then.
	if(!reactor)
		for(var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/R in GLOB.machines)
			if(R.z == usr.z)
				reactor = R
				break
	active = TRUE

/datum/computer_file/program/nuclear_monitor/kill_program(forced = FALSE)
	active = FALSE
	..()

/datum/computer_file/program/nuclear_monitor/ui_data()
	var/list/data = get_header_data()
	data["powerData"] = powerData
	data["kpaData"] = kpaData
	data["tempCoreData"] = tempCoreData
	data["tempInputData"] = tempInputData
	data["tempOutputData"] = tempOutputData
	data["coreTemp"] = reactor ? reactor.temperature : 0
	data["coolantInput"] = reactor ? reactor.last_coolant_temperature : 0
	data["coolantOutput"] = reactor ? reactor.last_output_temperature : 0
	data["power"] = reactor ? reactor.last_power_produced : 0
	data["kpa"] = reactor ? reactor.pressure : 0
	data["k"] = reactor ? reactor.K : 0
	return data

/datum/computer_file/program/nuclear_monitor/ui_act(action, params)
	if(..())
		return TRUE

	switch(action)
		if("swap_reactor")
			var/list/choices = list()
			for(var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/R in GLOB.machines)
				if(R.z != usr.z)
					continue
				choices += R
			reactor = input(usr, "What reactor do you wish to monitor?", "[src]", null) as null|anything in choices
			powerData = list()
			kpaData = list()
			tempCoreData = list()
			tempInputData = list()
			tempOutputData = list()
			return TRUE

/obj/effect/decal/nuclear_waste
	name = "plutonium sludge"
	desc = "A writhing pool of heavily irradiated, spent reactor fuel. You probably shouldn't step through this..."
	icon = 'icons/obj/machines/reactor_parts.dmi'
	icon_state = "nuclearwaste"
	alpha = 150
	light_color = LIGHT_COLOR_GREEN
	color = "#ff9eff"

/obj/effect/decal/nuclear_waste/Initialize(mapload)
	. = ..()
	for(var/obj/A in get_turf(src))
		if(istype(A, /obj/structure))
			qdel(src) //It is more processing efficient to do this here rather than when searching for available turfs.
	set_light(1)
	AddComponent(/datum/component/radioactive, 1000, src, 0)

/obj/effect/decal/nuclear_waste/epicenter //The one that actually does the irradiating. This is to avoid every bit of sludge PROCESSING
	name = "Dense nuclear sludge"

/obj/effect/landmark/nuclear_waste_spawner //Clean way of spawning nuclear gunk after a reactor core meltdown.
	name = "Nuclear waste spawner"
	var/range = 15 //15 tile radius to spawn goop

/obj/effect/landmark/nuclear_waste_spawner/strong
	range = 30

/obj/effect/landmark/nuclear_waste_spawner/proc/fire()
	playsound(loc, 'sound/effects/gib_step.ogg', 100)
	new /obj/effect/decal/nuclear_waste/epicenter(get_turf(src))
	for(var/turf/open/floor in orange(range, get_turf(src)))
		if(prob(35)) //Scatter the sludge, don't smear it everywhere
			new /obj/effect/decal/nuclear_waste (floor)
	qdel(src)

/obj/effect/decal/nuclear_waste/epicenter/Initialize(mapload)
	. = ..()

/obj/effect/decal/nuclear_waste/Crossed(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		playsound(loc, 'sound/effects/gib_step.ogg', HAS_TRAIT(L, TRAIT_LIGHT_STEP) ? 20 : 50, 1)
	radiation_pulse(src, 500, 5) //MORE RADS

/obj/effect/decal/nuclear_waste/attackby(obj/item/tool, mob/user)
	if(tool.tool_behaviour == TOOL_SHOVEL)
		radiation_pulse(src, 1000, 5) //MORE RADS
		to_chat(user, span_notice("You start to clear [src]..."))
		if(tool.use_tool(src, user, 50, volume=100))
			to_chat(user, span_notice("You clear [src]. "))
			qdel(src)
			return
	. = ..()

/datum/weather/nuclear_fallout
	name = "nuclear fallout"
	desc = "Irradiated dust falls down everywhere."
	telegraph_duration = 50
	telegraph_message = "<span class='boldwarning'>The air suddenly becomes dusty..</span>"
	weather_message = "<span class='userdanger'><i>You feel a wave of hot ash fall down on you.</i></span>"
	weather_overlay = "light_ash"
	telegraph_overlay = "light_snow"
	weather_duration_lower = 600
	weather_duration_upper = 1500
	weather_color = "green"
	telegraph_sound = null
	weather_sound = 'sound/effects/reactor/falloutwind.ogg'
	end_duration = 100
	area_type = /area
	protected_areas = list(/area/maintenance, /area/ai_monitored/turret_protected/ai_upload, /area/ai_monitored/turret_protected/ai_upload_foyer,
	/area/ai_monitored/turret_protected/ai, /area/shuttle)
	target_trait = ZTRAIT_STATION
	end_message = "<span class='notice'>The ash stops falling.</span>"
	immunity_type = "rad"

/datum/weather/nuclear_fallout/weather_act(mob/living/L)
	L.rad_act(100)

/datum/weather/nuclear_fallout/telegraph()
	..()
	status_alarm(TRUE)

/datum/weather/nuclear_fallout/proc/status_alarm(active)	//Makes the status displays show the radiation warning for those who missed the announcement.
	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)
	if(!frequency)
		return

	var/datum/signal/signal = new
	if (active)
		signal.data["command"] = "alert"
		signal.data["picture_state"] = "radiation"
	else
		signal.data["command"] = "shuttle"

	var/atom/movable/virtualspeaker/virt = new(null)
	frequency.post_signal(virt, signal)

/datum/weather/nuclear_fallout/end()
	if(..())
		return
	status_alarm(FALSE)

/obj/item/sealant
	name = "Flexi seal"
	desc = "A neat spray can that can repair torn inflatable segments, and more!"
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "sealant"
	w_class = WEIGHT_CLASS_TINY

/area/engineering/main/reactor_core
	name = "Nuclear Reactor Core"

/area/engineering/main/reactor_control
	name = "Reactor Control Room"


//Procs shamelessly taken from machinery/power
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/connect_to_network()
	var/turf/T = src.loc
	if(!T || !istype(T))
		return FALSE

	var/obj/structure/cable/C = T.get_cable_node() //check if we have a node cable on the machine turf, the first found is picked
	if(!C || !C.powernet)
		return FALSE

	C.powernet.add_machine(src)
	return TRUE

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/disconnect_from_network()
	if(!powernet)
		return FALSE
	powernet.remove_machine(src)
	return TRUE

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/add_avail(amount)
	if(powernet)
		powernet.newavail += amount
		return TRUE
	else
		return FALSE
