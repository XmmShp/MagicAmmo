/**
 * magicammo-specialammo.sp
 * Copyright (c) XmmShp 2019-2021. All Rights Reserved.
 *
 * The Subplugin of magicammo plugin
 * Part special Ammo
 */
#pragma semicolon 1
#pragma newdecls required

#include <smlib2>
#include <magicammo>

public Plugin myinfo ={
	name = "MagicAmmo-specialammo",
	author = "XmmShp",
	description = "The specialammo part of Magicammo plugin",
	version = "1.2.0.0", // Follows git commit
	url = "https://github.com/XmmShp/MagicAmmo"
};

public void OnPluginStart(){
	SetChatPrefix("[{purple}MagicAmmo{default}]");
}

void ShortenVector(float vec[3],float len=100.0){
	float rate=len/GetVectorLength(vec);
	vec[0]/=rate,vec[1]/=rate,vec[2]/=rate;
}

public void MagicAmmo_OnTakeDamage(int victim, int attacker,float damage, int weapon, float damageForce[3], char[] ammoname){
	if(strcmp(ammoname,"knockback_sp")==0){
		ShortenVector(damageForce,500.0);
		if(damageForce[2]<100.0)damageForce[2]=100.0;
		ToolsSetVelocity(victim,damageForce);
	}
	if(strcmp(ammoname,"showdamage_sp")==0){
		Chat(attacker,"^{yellow}来自 StatTrak™ 显伤追踪技术{defalult}^ : 你击中了 %N 造成了 %.0f 点伤害!",victim,damage);
	}
}

public void MagicAmmo_OnBulletFire(int client, int weapon, float vpos[3],char[] ammoname){
	if(strcmp(ammoname,"explode_sp")==0){
		UTIL_CreateExplosion(vpos,_,_,120.0,_,_,client,_,_);
	}
}