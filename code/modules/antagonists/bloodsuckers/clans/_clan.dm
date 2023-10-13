/**
 * Bloodsucker clans
 *
 * Handles everything related to clans.
 * the entire idea of datumizing this came to me in a dream.
 */
/datum/bloodsucker_clan
	///The bloodsucker datum that owns this clan. Use this over 'source', because while it's the same thing, this is more consistent (and used for deletion).
	var/datum/antagonist/bloodsucker/bloodsuckerdatum
	///The name of the clan we're in.
	var/name = CLAN_NONE
	///Description of what the clan is, given when joining and through your antag UI.
	var/description = "The Caitiff is as basic as you can get with Bloodsuckers. \n\
		Entirely Clan-less, they are blissfully unaware of who they really are. \n\
		No additional abilities is gained, nothing is lost, if you want a plain Bloodsucker, this is it. \n\
		The Favorite Vassal will gain the Brawn ability, to help in combat."
	///The clan objective that is required to greentext.
	var/datum/objective/clan_objective
	///The icon of the radial icon to join this clan.
	var/join_icon = 'icons/mob/bloodsucker_clan_icons.dmi'
	///Same as join_icon, but the state
	var/join_icon_state = "caitiff"
	///Description shown when trying to join the clan.
	var/join_description = "The default, Classic Bloodsucker."
	///Whether the clan can be joined by players. FALSE for flavortext-only clans.
	var/joinable_clan = TRUE

	///How the Bloodsucker ranks up, if they do.
	var/rank_up_type = BLOODSUCKER_RANK_UP_NORMAL
	///Whether they become entirely stun immune when entering Frenzy.
	var/frenzy_stun_immune = FALSE
	///The clan's manipulation specialty.
	var/control_type = BLOODSUCKER_CONTROL_BLOOD
	///How we will drink blood using Feed.
	var/blood_drink_type = BLOODSUCKER_DRINK_NORMAL

/datum/bloodsucker_clan/New(datum/antagonist/bloodsucker/owner_datum)
	. = ..()
	src.bloodsuckerdatum = owner_datum

	RegisterSignal(bloodsuckerdatum, COMSIG_BLOODSUCKER_ON_LIFETICK, PROC_REF(handle_clan_life))
	RegisterSignal(bloodsuckerdatum, BLOODSUCKER_RANK_UP, PROC_REF(on_spend_rank))

	RegisterSignal(bloodsuckerdatum, BLOODSUCKER_PRE_MAKE_FAVORITE, PROC_REF(on_offer_favorite))
	RegisterSignal(bloodsuckerdatum, BLOODSUCKER_MAKE_FAVORITE, PROC_REF(on_favorite_vassal))

	RegisterSignal(bloodsuckerdatum, BLOODSUCKER_MADE_VASSAL, PROC_REF(on_vassal_made))
	RegisterSignal(bloodsuckerdatum, BLOODSUCKER_EXIT_TORPOR, PROC_REF(on_exit_torpor))
	RegisterSignal(bloodsuckerdatum, BLOODSUCKER_FINAL_DEATH, PROC_REF(on_final_death))

	give_clan_objective()

/datum/bloodsucker_clan/Destroy(force)
	UnregisterSignal(bloodsuckerdatum, list(
		COMSIG_BLOODSUCKER_ON_LIFETICK,
		BLOODSUCKER_RANK_UP,
		BLOODSUCKER_PRE_MAKE_FAVORITE,
		BLOODSUCKER_MAKE_FAVORITE,
		BLOODSUCKER_MADE_VASSAL,
		BLOODSUCKER_EXIT_TORPOR,
		BLOODSUCKER_FINAL_DEATH,
	))
	remove_clan_objective()
	bloodsuckerdatum = null
	return ..()

///legacy code support
/datum/bloodsucker_clan/proc/get_clan()
	return name

/datum/bloodsucker_clan/proc/give_clan_objective()
	if(isnull(clan_objective))
		return
	clan_objective = new clan_objective()
	clan_objective.objective_name = "Clan Objective"
	clan_objective.owner = bloodsuckerdatum.owner
	bloodsuckerdatum.objectives += clan_objective
	bloodsuckerdatum.owner.announce_objectives()

/datum/bloodsucker_clan/proc/remove_clan_objective()
	bloodsuckerdatum.objectives -= clan_objective
	QDEL_NULL(clan_objective)
	bloodsuckerdatum.owner.announce_objectives()

/**
 * Called when a Bloodsucker exits Torpor
 * args:
 * source - the Bloodsucker exiting Torpor
 */
/datum/bloodsucker_clan/proc/on_exit_torpor(datum/antagonist/bloodsucker/source)
	SIGNAL_HANDLER


/**
 * Called when a Bloodsucker enters Final Death
 * args:
 * source - the Bloodsucker exiting Torpor
 */
/datum/bloodsucker_clan/proc/on_final_death(datum/antagonist/bloodsucker/source)
	SIGNAL_HANDLER
	return FALSE

/**
 * Called during Bloodsucker's LifeTick
 * args:
 * bloodsuckerdatum - the antagonist datum of the Bloodsucker running this.
 */
/datum/bloodsucker_clan/proc/handle_clan_life(datum/antagonist/bloodsucker/source)
	SIGNAL_HANDLER

/**
 * Called when a Bloodsucker successfully Vassalizes someone.
 * args:
 * bloodsuckerdatum - the antagonist datum of the Bloodsucker running this.
 */
/datum/bloodsucker_clan/proc/on_vassal_made(datum/antagonist/bloodsucker/source, mob/living/user, mob/living/target)
	SIGNAL_HANDLER
	user.playsound_local(null, 'sound/effects/explosion_distant.ogg', 40, TRUE)
	target.playsound_local(null, 'sound/effects/singlebeat.ogg', 40, TRUE)
	target.do_jitter_animation(15)
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob, emote), "laugh")

/**
 * Called when a Bloodsucker successfully starts spending their Rank
 * args:
 * bloodsuckerdatum - the antagonist datum of the Bloodsucker running this.
 * target - The Vassal (if any) we are upgrading.
 * cost_rank - TRUE/FALSE on whether this will cost us a rank when we go through with it.
 * blood_cost - A number saying how much it costs to rank up
 * ask - If they want to automatically spend the rest of their ranks
 */
/datum/bloodsucker_clan/proc/on_spend_rank(datum/antagonist/bloodsucker/source, mob/living/carbon/target, cost_rank = TRUE, blood_cost, ask)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(spend_rank), bloodsuckerdatum, cost_rank, blood_cost, ask)

/datum/bloodsucker_clan/proc/spend_rank(datum/antagonist/bloodsucker/source, cost_rank = TRUE, blood_cost, ask)
	// Purchase Power Prompt
	var/list/options = list()
	for(var/datum/action/cooldown/bloodsucker/power as anything in bloodsuckerdatum.all_bloodsucker_powers)
		if(initial(power.purchase_flags) & BLOODSUCKER_CAN_BUY && !(locate(power) in bloodsuckerdatum.powers))
			options[initial(power.name)] = power

	if(!LAZYLEN(options))
		to_chat(bloodsuckerdatum.owner.current, span_notice("You grow more ancient by the night!"))
	else
		// Give them the UI to purchase a power.
		var/choice = tgui_input_list(bloodsuckerdatum.owner.current, "You have the opportunity to grow more ancient. Select a power to advance your Rank.", "Your Blood Thickens...", options)
		// Prevent Bloodsuckers from closing/reopning their coffin to spam Levels.
		if(cost_rank && bloodsuckerdatum.bloodsucker_level_unspent <= 0)
			return
		// Did you choose a power?
		if(!choice || !options[choice])
			to_chat(bloodsuckerdatum.owner.current, span_notice("You prevent your blood from thickening just yet, but you may try again later."))
			return
		// Prevent Bloodsuckers from closing/reopning their coffin to spam Levels.
		if(locate(options[choice]) in bloodsuckerdatum.powers)
			to_chat(bloodsuckerdatum.owner.current, span_notice("You prevent your blood from thickening just yet, but you may try again later."))
			return
		// Prevent Bloodsuckers from purchasing a power while outside of their Coffin.
		if(!istype(bloodsuckerdatum.owner.current.loc, /obj/structure/closet/crate/coffin))
			to_chat(bloodsuckerdatum.owner.current, span_warning("You must be in your Coffin to purchase Powers."))
			return

		// Good to go - Buy Power!
		var/datum/action/cooldown/bloodsucker/purchased_power = options[choice]
		bloodsuckerdatum.BuyPower(new purchased_power)
		bloodsuckerdatum.owner.current.balloon_alert(bloodsuckerdatum.owner.current, "learned [choice]!")
		to_chat(bloodsuckerdatum.owner.current, span_notice("You have learned how to use [choice]!"))

	finalize_spend_rank(bloodsuckerdatum, cost_rank, blood_cost, ask)

/datum/bloodsucker_clan/proc/finalize_spend_rank(datum/antagonist/bloodsucker/source, cost_rank = TRUE, blood_cost, ask)
	bloodsuckerdatum.LevelUpPowers()
	bloodsuckerdatum.bloodsucker_regen_rate += 0.05
	bloodsuckerdatum.max_blood_volume += 100

	// Misc. Stats Upgrades
	if(ishuman(bloodsuckerdatum.owner.current))
		var/mob/living/carbon/human/user = bloodsuckerdatum.owner.current
		var/datum/species/user_species = user.dna.species
		user_species.punchdamagelow += 0.5
		// This affects the hitting power of Brawn.
		user_species.punchdamagehigh += 0.5
		user_species.punchstunthreshold += 0.5

	// We're almost done - Spend your Rank now.
	bloodsuckerdatum.bloodsucker_level++
	if(cost_rank)
		bloodsuckerdatum.bloodsucker_level_unspent--
	if(blood_cost)
		bloodsuckerdatum.AddBloodVolume(-blood_cost)

	// Ranked up enough to get your true Reputation?
	if(bloodsuckerdatum.bloodsucker_level == 4)
		bloodsuckerdatum.SelectReputation(am_fledgling = FALSE, forced = TRUE)

	to_chat(bloodsuckerdatum.owner.current, span_notice("You are now a rank [bloodsuckerdatum.bloodsucker_level] Bloodsucker. \
		Your strength, health, feed rate, regen rate, and maximum blood capacity have all increased! \n\
		* Your existing powers have all ranked up as well!"))
	if(ask) //please no
		bloodsuckerdatum.owner.current.playsound_local(null, 'sound/effects/pope_entry.ogg', 25, TRUE, pressure_affected = FALSE)
	bloodsuckerdatum.update_hud()
	if(bloodsuckerdatum.bloodsucker_level_unspent && cost_rank)
		if(ask)
			if(tgui_alert(bloodsuckerdatum.owner.current, "You have leftover ranks, do you want to spend them all?", "Time Management Team", list("Yes", "No")) == "No")
				return
		spend_rank(bloodsuckerdatum, cost_rank, blood_cost, FALSE)

/**
 * Called when we are trying to turn someone into a Favorite Vassal
 * args:
 * bloodsuckerdatum - the antagonist datum of the Bloodsucker performing this.
 * vassaldatum - the antagonist datum of the Vassal being offered up.
 */
/datum/bloodsucker_clan/proc/on_offer_favorite(datum/antagonist/bloodsucker/source, datum/antagonist/vassal/vassaldatum)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(offer_favorite), bloodsuckerdatum, vassaldatum)

/datum/bloodsucker_clan/proc/offer_favorite(datum/antagonist/bloodsucker/source, datum/antagonist/vassal/vassaldatum)
	if(vassaldatum.special_type)
		to_chat(bloodsuckerdatum.owner.current, span_notice("This Vassal was already assigned a special position."))
		return FALSE
	if(!vassaldatum.owner.can_make_special(creator = bloodsuckerdatum.owner))
		to_chat(bloodsuckerdatum.owner.current, span_notice("This Vassal is unable to gain a Special rank due to innate features."))
		return FALSE

	var/list/options = list()
	var/list/radial_display = list()
	for(var/datum/antagonist/vassal/vassaldatums as anything in subtypesof(/datum/antagonist/vassal))
		if(bloodsuckerdatum.special_vassals[initial(vassaldatums.special_type)])
			continue
		options[initial(vassaldatums.name)] = vassaldatums

		var/datum/radial_menu_choice/option = new
		option.image = image(icon = initial(vassaldatums.hud_icon), icon_state = initial(vassaldatums.antag_hud_name))
		option.info = "[initial(vassaldatums.name)] - [span_boldnotice(initial(vassaldatums.vassal_description))]"
		radial_display[initial(vassaldatums.name)] = option

	if(!options.len)
		return

	to_chat(bloodsuckerdatum.owner.current, span_notice("You can change who this Vassal is, who are they to you?"))
	var/vassal_response = show_radial_menu(bloodsuckerdatum.owner.current, vassaldatum.owner.current, radial_display)
	if(!vassal_response)
		return
	vassal_response = options[vassal_response]
	if(QDELETED(src) || QDELETED(bloodsuckerdatum.owner.current) || QDELETED(vassaldatum.owner.current))
		return FALSE
	vassaldatum.make_special(vassal_response)
	bloodsuckerdatum.bloodsucker_blood_volume -= 150

/**
 * Called when we are successfully turn a Vassal into a Favorite Vassal
 * args:
 * bloodsuckerdatum - antagonist datum of the Bloodsucker who turned them into a Vassal.
 * vassaldatum - the antagonist datum of the Vassal being offered up.
 */
/datum/bloodsucker_clan/proc/on_favorite_vassal(datum/antagonist/bloodsucker/source, datum/antagonist/vassal/vassaldatum)
	SIGNAL_HANDLER
	vassaldatum.BuyPower(new /datum/action/cooldown/bloodsucker/targeted/brawn)
