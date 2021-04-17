/**
 * magicammo.sp
 * Copyright (c) XmmShp 2019-2021. All Rights Reserved.
 *
 * The Core of magicammo plugin
 */

#pragma semicolon 1
#pragma newdecls required

#define MAXAMMOTYPE 64
#define MAXWEAPONNUM 70

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
	int Index;
	char Name[32];
	int Price;
	int BuyMode;//0->All 1->PreRound 2->InRound
	int OneGrp;
	ArrayList AllowedWeapon; //
}

enum struct ServerData
{
	StringMap AmmoMap;
	StringMapSnapshot AmmoSnapshot;
}

ServerData gServerData;

enum struct ClientData
{
	// ArrayList AmmoNum;
	int AmmoNum[MAXAMMOTYPE];
	int WeaponAmmo[MAXWEAPONNUM];
	bool Hit;
	int LastWeapon;
	void Init(){
		for(int i=0;i<MAXAMMOTYPE;i++)
			this.AmmoNum[i]=0;
		for(int i=0;i<MAXWEAPONNUM;i++)
			this.WeaponAmmo[i]=0;
		this.Hit=false;
		this.LastWeapon=0;
	}
}
ClientData gClientData[MAXPLAYERS + 1];

enum struct forward_t
{
	GlobalForward OnTakeDamage;
	GlobalForward OnBulletFire;

	void Init()
	{
		this.OnTakeDamage = new GlobalForward("MagicAmmo_OnTakeDamage", ET_Ignore, Param_Cell, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_Array);
		this.OnBulletFire = new GlobalForward("MagicAmmo_OnBulletFire", ET_Ignore, Param_Cell, Param_Cell, Param_Array);
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

	void _OnBulletFire(int client,int weapon,float vpos[3])
	{
		Call_StartForward(this.OnBulletFire);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushArray(vpos,3);
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
	// LoadCFGofAmmo();
	HookEvent("bullet_impact",Event_BulletImpact);
	HookEvent("weapon_fire",Event_WeaponFire);
	HookEvent("player_death",Event_PlayerDeath);

	RegConsoleCmd("out_info", cmd_out_info,"Print The Info Of The Item");
	RegConsoleCmd("mgc_toggle",cmd_toggle_ammo);
}


public Action cmd_out_info(int client, int params){
	if (params < 1)
	{
		return Plugin_Handled;
	}

	char sArg[32];
	GetCmdArg(1, string(sArg));

	AmmoData data;
	gServerData.AmmoMap.GetArray(sArg, data, sizeof(AmmoData));

	PrintToServer(data.Name);

	for (int i=0; i < data.AllowedWeapon.Length; i++)
	{
		PrintToServer("idx: %d", data.AllowedWeapon.Get(i));
	}

	return Plugin_Handled;
}
public Action cmd_toggle_ammo(int client, int args) {
	if(!IsPlayerExist(client))return;
	ToggleModeOfAmmo(client);
}


void ToggleModeOfAmmo(int client,int Mode=-1){
	if(!IsPlayerExist(client))return;
	int iWeapon=GetEntProp(ToolsGetActiveWeapon(client), Prop_Send, "m_iItemDefinitionIndex");
	if (!IsFirableWeapon(iWeapon))return;

	if(Mode==-1){
		gClientData[client].WeaponAmmo[iWeapon]++;
		if(gClientData[client].WeaponAmmo[iWeapon]>=gServerData.AmmoMap.Size)
			gClientData[client].WeaponAmmo[iWeapon]=0;
	}
	else if(Mode==gClientData[client].WeaponAmmo[iWeapon])return;
	else if(IsValidAmmo(Mode,iWeapon))gClientData[client].WeaponAmmo[iWeapon]=Mode;
	else return;
	
	if(!gClientData[client].WeaponAmmo[iWeapon])
		PrintToChat(client,"当前子弹 : 普通子弹");
	else if(gClientData[client].AmmoNum[gClientData[client].WeaponAmmo[iWeapon]]>0 && IsValidAmmo(gClientData[client].WeaponAmmo[iWeapon],iWeapon)){
			AmmoData ammodata;
			GetAmmoByIndex(gClientData[client].WeaponAmmo[iWeapon],ammodata);
			PrintToChat(client,"当前子弹 : %s , 剩余数量 %d 枚",ammodata.Name,gClientData[client].AmmoNum[gClientData[client].WeaponAmmo[iWeapon]]);
		}
	else ToggleModeOfAmmo(client);	
}

public void OnMapStart(){
	LoadCFGofAmmo();
}

public void OnClientPostAdminCheck(int client){
	if (IsPlayerExist(client, false))
	{
		gClientData[client].Init();
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]){
	// if(!IsPlayerExist(attacker)||!IsPlayerExist(victim))return Plugin_Continue;
	// int weaponid=GetClientActiveWeapon(attacker);
	// if(IsKnife(view_as<ItemDef>(weaponid))||IsProjectile(view_as<ItemDef>(weaponid)))return Plugin_Changed;
	// if(!ClientData[attacker].ammotype[weaponid])return Plugin_Changed;
	//_OnTakeDamage(int victim, int& attacker,float& damage, int& weapon, float damageForce[3])
	gForward._OnTakeDamage(victim, attacker, damage, weapon, damageForce);
}

void LoadCFGofAmmo(){
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

void LoadAllAmmoData(KeyValues kv){
	ArrayList tempList = new ArrayList();
	kv.GotoFirstSubKey();
	do
	{
		AmmoData data;
		if(!view_as<bool>(kv.GetNum("m_Enabled", 0))) continue;
		char sSecName[NORMAL_LINE_LENGTH];
		if(!kv.GetSectionName(string(sSecName)))continue;
		kv.GetString("m_Name", string(data.Name),"NULL");
		data.Price=kv.GetNum("m_Price",0);
		data.BuyMode=kv.GetNum("m_BuyMode",0);
		data.OneGrp=kv.GetNum("m_BuyNumOnce",0);
		char sWeapon[64][NORMAL_LINE_LENGTH],buf[FILE_LINE_LENGTH];
		kv.GetString("m_AllowedWeapon",string(buf),"");
		int nWeapon = ExplodeString(buf, ",", sWeapon, sizeof(sWeapon), sizeof(sWeapon[]));
		tempList.Clear();
		for(int i=0;i<nWeapon;i++)
		{
			TrimString(sWeapon[i]);
			CS_GetTranslatedWeaponAlias(sWeapon[i],sWeapon[i],sizeof(sWeapon[]) );
			int iWeapon=CS_WeaponIDToItemDefIndex(CS_AliasToWeaponID(sWeapon[i]));
			if(view_as<ItemDef>(iWeapon)==ItemDef_Invalid)continue;
			tempList.Push(iWeapon);
		}
		data.AllowedWeapon = tempList.Clone();
		data.Index=gServerData.AmmoMap.Size+1;
		gServerData.AmmoMap.SetArray(sSecName,data,sizeof(AmmoData));
	} while (kv.GotoNextKey());

	gServerData.AmmoSnapshot=gServerData.AmmoMap.Snapshot();

	delete tempList;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast){
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(!IsPlayerExist(client,false))return;
	gClientData[client].Init();
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast){
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(!IsPlayerExist(client))return;
	char sWeapon[NORMAL_LINE_LENGTH];
	event.GetString("weapon",string(sWeapon));
	CS_GetTranslatedWeaponAlias(sWeapon,string(sWeapon));
	int iWeapon=CS_WeaponIDToItemDefIndex(CS_AliasToWeaponID(sWeapon));

	if (!IsFirableWeapon(iWeapon))return;

	gClientData[client].Hit=true;
	gClientData[client].LastWeapon=iWeapon;
}

public Action Event_BulletImpact(Event event, const char[] name, bool dontBroadcast){
	int client=GetClientOfUserId(event.GetInt("userid"));
	int iWeapon=gClientData[client].LastWeapon;

	if (!IsFirableWeapon(iWeapon))return;

	float vpos[3];
	vpos[0]=event.GetFloat("x");
	vpos[1]=event.GetFloat("y");
	vpos[2]=event.GetFloat("z");
	if(gClientData[client].Hit){
		gForward._OnBulletFire(client,iWeapon,vpos);
		gClientData[client].Hit=false;
	}
}

bool IsFirableWeapon(int weapon){
	ItemDef Weapon=view_as<ItemDef>(weapon);
	return IsPistol(Weapon) || IsSMG(Weapon) || IsSR(Weapon) || IsSG(Weapon) || IsMG(Weapon) || IsAR(Weapon);
}

bool GetAmmoByIndex(int index,AmmoData ammodata){
	if(index>gServerData.AmmoMap.Size || index <= 0)return false;
	index--;
	char buf[NORMAL_LINE_LENGTH];
	gServerData.AmmoSnapshot.GetKey(index,string(buf));
	gServerData.AmmoMap.GetArray(buf,ammodata,sizeof(AmmoData));
	return true;
}

/*
*@brief---------Check if the ammo index is suit for weapon or not
*
*@index---------The index of ammo
*@weapon--------The ItemDefination of weapon(-1 means no limit)
*
*@return--------True when ammo is existed and can use in this weapon
*/
bool IsValidAmmo(int index,int weapon=-1){
	AmmoData ammo;
	if(!GetAmmoByIndex(index,ammo))return false;
	if(weapon==-1)return true;
	if(ammo.AllowedWeapon.FindValue(weapon)!=-1)return true;
	return false;
}