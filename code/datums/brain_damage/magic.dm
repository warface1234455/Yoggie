//Magical traumas, caused by spells and curses.
//Blurs the line between the victim's imagination and reality
//Unlike regular traumas this can affect the victim's body and surroundings

/datum/brain_trauma/magic
	resilience = TRAUMA_RESILIENCE_LOBOTOMY

/datum/brain_trauma/magic/lumiphobia
	name = "Lumiphobia"
	desc = "Patient has an inexplicable adverse reaction to light."
	scan_desc = "light hypersensitivity"
	gain_text = span_warning("You feel a craving for darkness.")
	lose_text = span_notice("Light no longer bothers you.")
	var/next_damage_warning = 0

/datum/brain_trauma/magic/lumiphobia/on_life()
	..()
	var/turf/T = owner.loc
	if(istype(T))
		var/light_amount = T.get_lumcount()
		if(light_amount > SHADOW_SPECIES_LIGHT_THRESHOLD) //if there's enough light, start dying
			if(world.time > next_damage_warning)
				to_chat(owner, span_warning("<b>The light burns you!</b>"))
				next_damage_warning = world.time + 100 //Avoid spamming
			owner.take_overall_damage(0,3)

/datum/brain_trauma/magic/poltergeist
	name = "Poltergeist"
	desc = "Patient appears to be targeted by a violent invisible entity."
	scan_desc = "paranormal activity"
	gain_text = span_warning("You feel a hateful presence close to you.")
	lose_text = span_notice("You feel the hateful presence fade away.")

/datum/brain_trauma/magic/poltergeist/on_life()
	..()
	if(prob(10))
		var/list/obj/item/items_hitting_player = list()
		for(var/obj/item/nearby_item in view(5, get_turf(owner)))
			if(nearby_item.anchored)
				continue
			if(items_hitting_player.len != 5) //Pick 5 items around the user
				items_hitting_player += nearby_item
				continue
			for(var/obj/item/items_about_to_hit as anything in items_hitting_player)
				if(nearby_item.throwforce > items_about_to_hit.throwforce) //Take the stronger one and remove the weak one
					items_hitting_player += nearby_item
					items_hitting_player -= items_about_to_hit
					break
		for(var/obj/item/hit_items as anything in items_hitting_player) //NOW FUCKING TRHOW THEM
			hit_items.throw_at(owner, 8, 2)

/datum/brain_trauma/magic/antimagic
	name = "Athaumasia"
	desc = "Patient is completely inert to magical forces."
	scan_desc = "thaumic blank"
	gain_text = span_notice("You realize that magic cannot be real.")
	lose_text = span_notice("You realize that magic might be real.")

/datum/brain_trauma/magic/antimagic/on_gain()
	ADD_TRAIT(owner, TRAIT_ANTIMAGIC, TRAUMA_TRAIT)
	..()

/datum/brain_trauma/magic/antimagic/on_lose()
	REMOVE_TRAIT(owner, TRAIT_ANTIMAGIC, TRAUMA_TRAIT)
	..()

/datum/brain_trauma/magic/stalker
	name = "Stalking Phantom"
	desc = "Patient is stalked by a phantom only they can see."
	scan_desc = "extra-sensory paranoia"
	gain_text = span_warning("You feel like something wants to kill you...")
	lose_text = span_notice("You no longer feel eyes on your back.")
	var/list/stalkers = list()
	var/close_stalker = FALSE //For heartbeat

/datum/brain_trauma/magic/stalker/on_gain()
	create_stalker()
	..()

/datum/brain_trauma/magic/stalker/proc/create_stalker()
	var/turf/stalker_source
	var/anomaly_near = FALSE
	var/obj/effect/hallucination/simple/stalker_phantom/phantom
	for(var/obj/effect/anomaly/hallucination/anomaly in view(5, owner)) //If there are multiple hallucination anomalies nearby you are fucked
		if(anomaly)
			anomaly_near = TRUE
			stalker_source = anomaly.loc
			phantom = new(stalker_source, owner)
			stalkers += phantom
	if(!anomaly_near)
		stalker_source = locate(owner.x + pick(-12, 12), owner.y + pick(-12, 12), owner.z) //random corner
		phantom = new(stalker_source, owner)
		stalkers += phantom

/datum/brain_trauma/magic/stalker/on_lose()
	QDEL_LAZYLIST(stalkers)
	..()

/datum/brain_trauma/magic/stalker/on_life()
	// Dead and unconscious people are not interesting to the psychic stalker.
	if(owner.stat != CONSCIOUS)
		return
	for(var/obj/effect/hallucination/simple/stalker_phantom/stalker in stalkers)
	// Not even nullspace will keep it at bay.
		if(!stalker)
			create_stalker()

		if(!stalker.loc || stalker.z != owner.z)
			qdel(stalker)
			create_stalker()

		if(get_dist(owner, stalker) <= 1)
			playsound(owner, 'sound/magic/demon_attack1.ogg', 50)
			owner.visible_message(span_warning("[owner] is torn apart by invisible claws!"), span_userdanger("Ghostly claws tear your body apart!"))
			owner.take_bodypart_damage(rand(20, 45), wound_bonus=CANT_WOUND)
		else
			stalker.forceMove(get_step_towards(stalker, owner))

		if(get_dist(owner, stalker) <= 8)
			if(!close_stalker)
				var/sound/slowbeat = sound('sound/health/slowbeat.ogg', repeat = TRUE)
				owner.playsound_local(owner, slowbeat, 40, 0, channel = CHANNEL_HEARTBEAT)
				close_stalker = TRUE
		else
			if(close_stalker)
				owner.stop_sound_channel(CHANNEL_HEARTBEAT)
				close_stalker = FALSE
	..()

/obj/effect/hallucination/simple/stalker_phantom
	name = "???"
	desc = "It's coming closer..."
	image_icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	image_state = "curseblob"
