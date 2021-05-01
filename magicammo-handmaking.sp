/**
 * magicammo.sp
 * Copyright (c) XmmShp 2019-2021. All Rights Reserved.
 *
 * The Subplugin of magicammo plugin
 * Part Handmaking Ammo
 */
#pragma semicolon 1
#pragma newdecls required

#include <laper32>
#include <magicammo>

public Plugin myinfo ={
	name = "MagicAmmo-handmaking",
	author = "XmmShp",
	description = "The handmaking part of Magicammo plugin",
	version = "1.1.0.0", // Follows git commit
	url = "https://github.com/XmmShp/MagicAmmo"
};

public void MagicAmmo_OnTakeDamage(int victim, int attacker,float damage, int weapon, float damageForce[3], char[] ammoname){
	if(strcmp(ammoname,"SuperAmmo[Pistol]")==0){
		PrintToChat(attacker,"使用手工子弹造成2倍伤害");
		MagicAmmo_PostDamage(damage*2);
	}
	if(strcmp(ammoname,"SuperAmmo[SniperRifle]")==0){
		PrintToChat(attacker,"使用手工子弹造成1.5倍伤害");
		MagicAmmo_PostDamage(damage*1.5);
	}
}