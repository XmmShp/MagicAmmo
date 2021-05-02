/**
 * magicammo-handmaking.sp
 * Copyright (c) XmmShp 2019-2021. All Rights Reserved.
 *
 * The Subplugin of magicammo plugin
 * Part Handmaking Ammo
 */
#pragma semicolon 1
#pragma newdecls required

#include <smlib2>
#include <magicammo>

public Plugin myinfo ={
	name = "MagicAmmo-handmaking",
	author = "XmmShp",
	description = "The handmaking part of Magicammo plugin",
	version = "1.2.0.0", // Follows git commit
	url = "https://github.com/XmmShp/MagicAmmo"
};

public void OnPluginStart(){
	SetChatPrefix("[{purple}MagicAmmo{default}]");
}

public void MagicAmmo_OnTakeDamage(int victim, int attacker,float damage, int weapon, float damageForce[3], char[] ammoname){
	if(strcmp(ammoname,"pistol_hm")==0){
		MagicAmmo_PostDamage(damage*1.5);
	}
	if(strcmp(ammoname,"sniper_hm")==0){
		MagicAmmo_PostDamage(damage*1.3);
	}
	if(strcmp(ammoname,"rifle_hm")==0){
		MagicAmmo_PostDamage(damage*1.2);
	}
	if(strcmp(ammoname,"shotgun_hm")==0){
		MagicAmmo_PostDamage(damage*1.1);
	}
}