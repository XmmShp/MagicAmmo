/**
 * magicammo.sp
 * Copyright (c) XmmShp 2019-2021. All Rights Reserved.
 *
 * The Core of magicammo plugin
 */

#pragma semicolon 1
#pragma newdecls required

#include <laper32>

public Plugin myinfo =
{
	name = "MagicAmmo-Core",
	author = "XmmShp",
	description = "The core of Magicammo plugin",
	version = "1.0.0.0", // Follows git commit
	url = "https://github.com/XmmShp/MagicAmmo"
};

enum struct AmmoData // ammo_t
{
	char Name[32];
	int Price;
	int BuyMode;//0->All 1->PreRound 2->InRound
	int OneGrp;
	ArrayList AllowedWeapon; //
}

enum struct ServerData
{
	StringMap AmmoMap;
}

ServerData gServerData;

enum struct forward_t
{
	GlobalForward OnTakeDamage;
	GlobalForward OnBulletFire;

	void Init()
	{
		this.OnTakeDamage = new GlobalForward("MagicAmmo_OnTakeDamage", ET_Ignore, Param_Cell, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_Array);
		//Action MagicAmmo_OnTakedamage(int attacker,int victim,int weapon,int ammoid,...)
		//int victim, int& attacker,float& damage, int& weapon, float damageForce[3]
	}

	void _OnTakeDamage(int victim, int& attacker,float& damage, int& weapon, float damageForce[3])
	{
		Call_StartForward(this.OnTakeDamage);
		Call_PushCell(victim);
		Call_PushCellRef(attacker);
		Call_PushFloatRef(damage);
		Call_PushCellRef(weapon);
		Call_PushArray(damageForce,3);
		Call_Finish();
	}
}

forward_t gForward;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("MagicAmmo");
	gForward.Init();
	return APLRes_Success;
}

public void OnPluginStart()
{
	gServerData.AmmoMap = new StringMap();
}

public void MagicAmmo_OnTakeDamage(int victim, int& attacker,float& damage, int& weapon, float damageForce[3])
{

}

// 
public void OnMapStart()
{
	LoadCFGofAmmo();
}

public void OnClientPostAdminCheck(int client)
{
	if (IsPlayerExist(client, false))
	{
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
	// if(!IsPlayerExist(attacker)||!IsPlayerExist(victim))return Plugin_Continue;
	// int weaponid=GetClientActiveWeapon(attacker);
	// if(IsKnife(view_as<ItemDef>(weaponid))||IsProjectile(view_as<ItemDef>(weaponid)))return Plugin_Changed;
	// if(!ClientData[attacker].ammotype[weaponid])return Plugin_Changed;
	//_OnTakeDamage(int victim, int& attacker,float& damage, int& weapon, float damageForce[3])
	gForward._OnTakeDamage(victim, attacker, damage, weapon, damageForce);
}

void LoadCFGofAmmo()
{
	char path[256];
	BuildPath(Path_SM, string(path), "configs/magicammo/magicammo.kv");
	KeyValues kv = new KeyValues("Ammo");

	if (!FileExists(path))
	{
		SetFailState("FATAL: KeyValues file doesn't exist: %s", path);
		return;
	}
	else
	{
		kv.ImportFromFile(path);
		LoadAllAmmoData(kv);
	}
	delete kv;
}

void LoadAllAmmoData(KeyValues kv)
{
	ArrayList tempList = new ArrayList();
	kv.GotoFirstSubKey();
	do
	{
		AmmoData data;
		if(view_as<bool>(kv.GetNum("m_Enabled", 0))) continue;
		kv.GetString("m_Name", string(data.Name),"NULL");
		data.Price=kv.GetNum("m_Price",0);
		data.BuyMode=kv.GetNum("m_BuyMode",0);
		data.OneGrp=kv.GetNum("m_BuyNumOnce",0);
		char sWeapon[64][32],buf[1024];
		kv.GetString("m_AllowedWeapon",string(buf),"");
		int nWeapon = ExplodeString(buf, ",", sWeapon, sizeof(sWeapon), sizeof(sWeapon[]));
		tempList.Clear();
		for(int i=0;i<nWeapon;i++)
		{
			TrimString(sWeapon[i]);
			tempList.Push(CS_WeaponIDToItemDefIndex(CS_AliasToWeaponID(sWeapon[i])));
		}

		data.AllowedWeapon = tempList;
	} while (kv.GotoNextKey());
	delete tempList;
}

/* int index = 0;
	* char sIndex[32], sLanguage[32], sMessage[1024];
	// kv.GotoFirstSubKey();
	// do
	// {
	//     IntToString(index, sIndex, sizeof(sIndex));
	//     AdvertiseData data;
	//     data.m_bEnable = view_as<bool>(kv.GetNum("m_Enable", 0));

	//     ArrayList MessageArray = new ArrayList(128);
	//     if (kv.JumpToKey("m_Message"))
	//     {
	//         for (int i = 0; i < gServerData.SupportedLanguage.Length; i++)
	//         {
	//             gServerData.SupportedLanguage.GetString(i, sLanguage, sizeof(sLanguage));
	//             kv.GetString(sLanguage, sMessage, sizeof(sMessage), "");
	//             // If found that language is null string, then call default language
	//             // If default lang is null...well, check config...
	//             if (!hasLength(sMessage)) MessageArray.GetString(0, sMessage, sizeof(sMessage));
	//             MessageArray.PushString(sMessage);
	//         }
	//         kv.GoBack();
	//     }

	//     data.m_Message = MessageArray;

	//     kv.GetString("m_AllowedMap", data.m_AllowedMap, sizeof(data.m_AllowedMap), "all");
	//     kv.GetString("m_BannedMap", data.m_BannedMap, sizeof(data.m_BannedMap), "");
	//     data.m_eMethod = view_as<AdvertiseMethod>(kv.GetNum("m_eMethod", 0));

	//     if (data.m_eMethod == Method_HudText)
	//     {
	//         if (kv.JumpToKey("m_HudParams"))
	//         {
	//             data.params.x = kv.GetFloat("x", -1.0);
	//             data.params.y = kv.GetFloat("y", -1.0);
	//             data.params.holdtime = kv.GetFloat("holdtime", 0.0);
	//             data.params.effect = kv.GetNum("effect", 0);
	//             data.params.fxTime = kv.GetFloat("fxTime", 0.0);
	//             data.params.fadeIn = kv.GetFloat("fadeIn", 0.0);
	//             data.params.fadeOut = kv.GetFloat("fadeOut", 0.0);

	//             if (kv.JumpToKey("m_HudColor1"))
	//             {
	//                 data.params.color1.r = kv.GetNum("r", 255);
	//                 data.params.color1.g = kv.GetNum("g", 255);
	//                 data.params.color1.b = kv.GetNum("b", 255);
	//                 data.params.color1.a = kv.GetNum("a", 255);
	//                 kv.GoBack();
	//             }

	//             if (kv.JumpToKey("m_HudColor2"))
	//             {
	//                 data.params.color2.r = kv.GetNum("r", 255);
	//                 data.params.color2.g = kv.GetNum("g", 255);
	//                 data.params.color2.b = kv.GetNum("b", 255);
	//                 data.params.color2.a = kv.GetNum("a", 255);
	//                 kv.GoBack();
	//             }
	//             kv.GoBack();
	//         }
	//     }

	//     gServerData.AdvertiseMap.SetArray(sIndex, data, sizeof(AdvertiseData), true);
	//     index++;
	/ } while (kv.GotoNextKey());    */
	