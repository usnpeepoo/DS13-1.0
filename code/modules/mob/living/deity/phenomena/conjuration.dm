/datum/phenomena/dimensional_locker
	name = "Dimensional Locker"
	cost = 10
	desc = "Summon a trans-dimensional locker anywhere within your influence. You may transport objects and things, but not people in it."
	flags = PHENOMENA_NEAR_STRUCTURE|PHENOMENA_MUNDANE|PHENOMENA_FOLLOWER|PHENOMENA_NONFOLLOWER
	var/obj/structure/closet/cabinet
	var/cabinet_type = /obj/structure/closet/cabinet
	expected_type = /atom

/datum/phenomena/dimensional_locker/New()
	..()
	cabinet = new cabinet_type()

/datum/phenomena/dimensional_locker/Destroy()
	if(!cabinet.loc)
		QDEL_NULL(cabinet)
	. = ..()

/datum/phenomena/dimensional_locker/activate(var/atom/a, var/mob/living/deity/user)
	..()
	for(var/i in cabinet)
		if(ismob(i))
			var/mob/M = i
			M.forceMove(get_turf(cabinet))
			to_chat(M,"<span class='warning'>You are suddenly flung out of \the [cabinet]!</span>")
	if(cabinet == a)
		cabinet.forceMove(null) //Move to null space
	else
		var/turf/T = get_turf(a)
		//No dense turf/stuff
		if(T.density)
			return
		for(var/i in T)
			var/atom/A = i
			if(A.density)
				return
		cabinet.forceMove(T)

/datum/phenomena/portals
	name = "Portals"
	desc = "Summon a portal linked to the last portal you've created. The portal will be destroyed if it is not linked when someone crosses it."
	cost = 30
	flags = PHENOMENA_NEAR_STRUCTURE|PHENOMENA_MUNDANE|PHENOMENA_FOLLOWER|PHENOMENA_NONFOLLOWER
	expected_type = /atom
	var/list/portals = list()

/datum/phenomena/portals/activate(var/atom/a, var/mob/living/deity/user)
	..()
	var/obj/effect/portal/P = new(get_turf(a), null, 0)
	P.failchance = 0
	portals += P
	RegisterSignal(P, COMSIG_PARENT_QDELETING, .proc/remove_portal)
	if(portals.len > 2)
		var/removed = portals[1]
		remove_portal(removed)
		qdel(removed)
	if(portals.len > 1)
		var/obj/effect/portal/P1 = portals[1]
		var/obj/effect/portal/P2 = portals[2]
		P1.target = get_turf(P2)
		P2.target = get_turf(P1)

/datum/phenomena/portals/proc/remove_portal(var/portal)
	SIGNAL_HANDLER
	portals -= portal
	UnregisterSignal(portal, COMSIG_PARENT_QDELETING)
	var/turf/T = get_turf(portal)
	for(var/obj/effect/portal/P in portals)
		if(P.target == T)
			P.target = null

/datum/phenomena/banishing_smite
	name = "Banishing Smite"
	desc = "Deal a terrible blow to a mortal. If they are hurt enough ,they will find themselves trapped in a rift for 30 seconds."
	cost = 70
	cooldown = 300
	flags = PHENOMENA_NEAR_STRUCTURE|PHENOMENA_MUNDANE|PHENOMENA_FOLLOWER|PHENOMENA_NONFOLLOWER
	expected_type = /mob/living

/datum/phenomena/banishing_smite/activate(var/mob/living/L, var/mob/living/deity/user)
	..()
	L.take_overall_damage(rand(5,30),0,0,0,"blunt intrument") //Actual spell does 5d10 but maaaybe too much.
	playsound(get_turf(L), 'sound/effects/bamf.ogg', 100, 1)
	to_chat(L, "<span class='danger'>Something hard hits you!</span>")
	if(L.health < L.max_health/2) //If it reduces past 50%
		var/obj/effect/rift/R = new(get_turf(L))
		L.visible_message("<span class='danger'>\The [L] is quickly sucked into \a [R]!</span>")
		L.forceMove(R)
		spawn(300)
			qdel(R)

/obj/effect/rift
	name = "rift"
	desc = "a tear in space and time."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "rift"
	unacidable = 1
	anchored = 1
	density = 0

/obj/effect/rift/Destroy()
	for(var/o in contents)
		var/atom/movable/M = o
		M.forceMove(get_turf(src))
	. = ..()