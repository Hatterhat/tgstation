/**
 * should i have made this a crusher subtype?
 * probably.
 * however, this whole thing is
 * a failed wisdom check
 * - hatterhat
 */

/obj/item/kinetic_katana
	name = "proto-kinetic katana"
	desc = "Dumb desc todo for a dumb meme weapon. Note how the brunt of the damage is on sheath, not on slash. Literally no utility as a mining tool."
	// desc = "DANTEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
	w_class = WEIGHT_CLASS_HUGE
	icon = 'icons/obj/mining.dmi'
	icon_state = "katana_edit"
	inhand_icon_state = "katana"
	worn_icon_state = "katana"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 5
	obj_flags = UNIQUE_RENAME
	attack_verb_continuous = list("smashes", "crushes", "cleaves", "chops", "pulps")
	attack_verb_simple = list("smash", "crush", "cleave", "chop", "pulp")
	// trophy integration one day
	var/list/datum/status_effect/katana_mark/marks_list = list()
	var/slash_color = COLOR_WHITE
	var/max_marks = 3
	var/detonation_damage = 50
	var/backstab_bonus = 30
	var/charge_time = 15

/obj/item/kinetic_katana/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, \
		speed = 6 SECONDS, \
		effectiveness = 110, \
	)

/obj/item/kinetic_katana/on_exit_storage(datum/storage/container)
	var/obj/item/storage/belt/sabre/kinetic_scabbard/sabre = container.real_location?.resolve()
	if(istype(sabre))
		playsound(sabre, 'sound/items/unsheath.ogg', 25, TRUE)

/obj/item/kinetic_katana/on_enter_storage(datum/storage/container)
	var/obj/item/storage/belt/sabre/kinetic_scabbard/sabre = container.real_location?.resolve()
	if(istype(sabre))
		playsound(sabre, 'sound/items/sheath.ogg', 25, TRUE)
		detonate_marks()

/obj/item/kinetic_katana/attack(mob/living/target_mob, mob/living/user, params)
	var/datum/status_effect/crusher_damage/damage_tracker = target_mob.has_status_effect(/datum/status_effect/crusher_damage)
	if(!damage_tracker)
		damage_tracker = target_mob.apply_status_effect(/datum/status_effect/crusher_damage)
	var/target_health = target_mob.health
	..()
	var/backstab_dir = get_dir(user, target_mob)
	var/backstab_check = ((user.dir & backstab_dir) && (target_mob.dir & backstab_dir))
	handle_mark(target_mob, backstab_check, user)
	if(!QDELETED(damage_tracker) && !QDELETED(target_mob))
		damage_tracker.total_damage += target_health - target_mob.health

/obj/item/kinetic_katana/proc/handle_mark(mob/living/target_mob, backstab_check, mob/living/user)
	if(marks_list.len < max_marks)
		var/datum/status_effect/katana_mark/new_mark = target_mob.apply_status_effect(/datum/status_effect/katana_mark, src, backstab_check)
		if(new_mark)
			marks_list.Add(new_mark)
			user.balloon_alert(user, "[max_marks - marks_list.len] marks left")
	else
		user.balloon_alert(user, "no marks, recharge!")

/obj/item/kinetic_katana/proc/detonate_marks()
	for(var/datum/status_effect/katana_mark/mark_to_det in marks_list)
		marks_list.Remove(mark_to_det)
		var/mob/living/cur_target = mark_to_det.owner
		var/datum/status_effect/crusher_damage/damage_tracker = cur_target.has_status_effect(/datum/status_effect/crusher_damage)
		if(!damage_tracker)
			damage_tracker = cur_target.apply_status_effect(/datum/status_effect/crusher_damage)
		var/target_health = cur_target.health
		var/def_check = cur_target.getarmor(type = BOMB)
		if(!QDELETED(damage_tracker) && !QDELETED(cur_target))
			var/damage_dealt = detonation_damage
			if(mark_to_det.is_backstab)
				damage_dealt += backstab_bonus
				damage_tracker.total_damage += damage_dealt // applying before actual apply_damage (also before possible actual kill!)
			cur_target.apply_damage(damage_dealt, BRUTE, blocked = def_check)
			damage_tracker.total_damage += target_health - cur_target.health
			new /obj/effect/temp_visual/slash(get_turf(cur_target), cur_target, world.icon_size/2, world.icon_size/2, slash_color)
			playsound(src, 'sound/weapons/zapbang.ogg', 50, vary = TRUE)

/obj/item/storage/belt/sabre/kinetic_scabbard
	name = "destabilizer saya"
	desc = "Dumb desc todo for a dumb meme weapon's scabbard. Sheath the blade, idiot."
	icon_state = "katana-sheath"
	w_class = WEIGHT_CLASS_HUGE
	var/datum/weakref/linked_katana

/obj/item/storage/belt/sabre/kinetic_scabbard/Initialize(mapload)
	. = ..()
	atom_storage.max_specific_storage = WEIGHT_CLASS_HUGE
	atom_storage.set_holdable(
		list(
			/obj/item/kinetic_katana,
		)
	)

/obj/item/storage/belt/sabre/kinetic_scabbard/PopulateContents()
	var/obj/item/kinetic_katana/our_katana = new /obj/item/kinetic_katana(src)
	linked_katana = WEAKREF(our_katana)
	update_appearance()
