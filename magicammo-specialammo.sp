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

public void OnMapStart(){
	PrecacheModel("materials/sprites/xfireball3.vmt", true);
}

void ShortenVector(float vec[3],float len=100.0){
	float rate=len/GetVectorLength(vec);
	vec[0]*=rate,vec[1]*=rate,vec[2]*=rate;
}



public void MagicAmmo_OnTakeDamage(int victim, int attacker,float damage, int weapon, float damageForce[3], char[] ammoname){
	if(strcmp(ammoname,"knockback_sp")==0){
		ShortenVector(damageForce,1000.0);
		if(damageForce[2]<260.0)damageForce[2]=260.0;
		ToolsSetVelocity(victim,damageForce);
	}
	if(strcmp(ammoname,"showdamage_sp")==0){
		SetChatPrefix("[{purple}MagicAmmo-显伤追踪技术{default}]");
		Chat(attacker,"你击中 %N 造成了 %.0f 点伤害!",victim,damage);
		SetChatPrefix("[{purple}MagicAmmo{default}]");
	}
	if(strcmp(ammoname,"invisible_sp")==0){
		MagicAmmo_PostDamage(10.0);
		int iFlags = ToolsGetEffect(victim);
		if(iFlags & EF_NODRAW) return;
		ToolsSetEffect(victim, iFlags | EF_NODRAW);
		CreateTimer(3.0,InvisibleProcess,victim);
	}
	if(strcmp(ammoname,"cure_sp")==0){
		MagicAmmo_PostDamage(0.0);
		int iHealth=ToolsGetHealth(victim);
		if(iHealth>=100)return;
		ToolsSetHealth(victim,iHealth+1);
	}
	
}

public void MagicAmmo_OnBulletFire(int client, int weapon, float vpos[3],char[] ammoname){
	if(strcmp(ammoname,"explode_sp")==0){
		UTIL_CreateExplosion(vpos,0, _, 55.0, 300.0, "m32", client, client);
	}
	if(strcmp(ammoname,"flash_sp")==0){
		DataPack pack=new DataPack();
		pack.WriteCell(1);
		pack.WriteFloat(vpos[0]);
		pack.WriteFloat(vpos[1]);
		pack.WriteFloat(vpos[2]);
		pack.WriteCell(client);
		CreateTimer(1.0,CreateFlash,pack);
	}
}

public Action InvisibleProcess(Handle timer,any client){
	if(!IsPlayerExist(client))return;
	int iFlags = ToolsGetEffect(client);
	ToolsSetEffect(client, iFlags & (~EF_NODRAW));
}

public Action CreateFlash(Handle timer,DataPack pack){
	pack.Reset();
	int tm,client;float vpos[3];
	tm=pack.ReadCell();vpos[0]=pack.ReadFloat();vpos[1]=pack.ReadFloat();vpos[2]=pack.ReadFloat();client=pack.ReadCell();
	if(tm==6)return;
	DataPack p2 = new DataPack();
	p2.WriteCell(tm+1);p2.WriteFloat(vpos[0]);p2.WriteFloat(vpos[1]);p2.WriteFloat(vpos[2]);p2.WriteCell(client);
	CreateTimer(5.0,CreateFlash,p2);
	int ientity=CreateEntityByName("flashbang_projectile");
	DispatchKeyValue(ientity, "classname", "flashbang_projectile");
	DispatchSpawn(ientity);
	TeleportEntity(ientity, vpos,NULL_VECTOR,NULL_VECTOR);
	AcceptEntityInput(ientity,"InitializeSpawnFromWorld");
}