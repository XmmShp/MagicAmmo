/**
 * magicammo-core.sp
 * Copyright (c) XmmShp 2019-2021. All Rights Reserved.
 *
 * The Core of magicammo plugin
 */

#pragma semicolon 1
#pragma newdecls required

#define MAXAMMOTYPE 64
#define MAXWEAPONNUM 70

#include<smlib2>

public Plugin myinfo ={
	name = "MagicAmmo-Core",
	author = "XmmShp",
	description = "The core of Magicammo plugin",
	version = "1.2.0.0", // Follows git commit
	url = "https://github.com/XmmShp/MagicAmmo"
};

//-------------------------- Defination of enum--------------------------------
enum Roundstate{
	RoundState_InFreezeTime=1,
	RoundState_InRound
};

enum BuyMode{
	BuyMode_InFreezeTime=1,
	BuyMode_InRound,
	BuyMode_InAll
};

//-------------------------- Defination of struct--------------------------------
enum struct AmmoData {
	int Index;
	char Key[32];
	char Name[32];
	char Description[CONSOLE_LINE_LENGTH];
	int Price;
	BuyMode BuyMode;
	int OneGrp;
	ArrayList AllowedWeapon; //
}

enum struct ServerData{
	StringMap AmmoMap;
	StringMapSnapshot AmmoSnapshot;
	float RespondDamage;
	Roundstate roundstate;
	bool dbgmode;
}
ServerData gServerData;

enum struct ClientData{
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

enum struct forward_t{
	GlobalForward OnTakeDamage;
	GlobalForward OnBulletFire;

	void Init()
	{
		this.OnTakeDamage = new GlobalForward("MagicAmmo_OnTakeDamage", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Array, Param_String);
		this.OnBulletFire = new GlobalForward("MagicAmmo_OnBulletFire", ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_String);
		//Action MagicAmmo_OnTakedamage(int attacker,int victim,int weapon,int ammoid,...)
		//int victim, int& attacker,float& damage, int& weapon, float damageForce[3]
	}

	void _OnTakeDamage(int victim, int attacker,float damage, int weapon, float damageForce[3],const char[] ammoname)
	{
		Call_StartForward(this.OnTakeDamage);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushFloat(damage);
		Call_PushCell(weapon);
		Call_PushArray(damageForce,3);
		Call_PushString(ammoname);
		Call_Finish();
	}

	void _OnBulletFire(int client,int weapon,float vpos[3],const char[] ammoname)
	{
		Call_StartForward(this.OnBulletFire);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushArray(vpos,3);
		Call_PushString(ammoname);
		Call_Finish();
	}
}
forward_t gForward;

//-------------------------- Functions Called by Forward--------------------------------
public void OnPluginStart(){
	gServerData.AmmoMap = new StringMap();
	// LoadCFGofAmmo();
	SetChatPrefix("[{purple}MagicAmmo{default}]");
	HookEvent("bullet_impact",Event_BulletImpact);
	HookEvent("weapon_fire",Event_WeaponFire);
	HookEvent("player_death",Event_PlayerDeath);
	HookEvent("round_start",Event_RoundStart);
	HookEvent("round_freeze_end",Event_FreezeEnd);

	RegConsoleCmd("mgc_toggle",cmd_toggle_ammo,"Toggle client's ammotype");
	RegConsoleCmd("mgc_callstore",cmd_call_store,"Show Menu Of Ammo to client");
	RegConsoleCmd("mgc_dbgmode",cmd_debug_mode);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){
	RegPluginLibrary("MagicAmmo");
	gForward.Init();
	CreateNative("MagicAmmo_PostDamage",Native_PostDamage);
	return APLRes_Success;
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

//-------------------------- Functions of practice--------------------------------
void ToggleModeOfAmmo(int client,int Mode=-1){
	if(!IsPlayerExist(client))return;
	int iWeapon=ToolsGetWeaponDefIndex(ToolsGetActiveWeapon(client));
	if (!IsFirableWeapon(iWeapon))return;

	if(Mode==-1){
		gClientData[client].WeaponAmmo[iWeapon]++;
		if(gClientData[client].WeaponAmmo[iWeapon]>gServerData.AmmoMap.Size)
			gClientData[client].WeaponAmmo[iWeapon]=0;
	}
	else if(Mode==gClientData[client].WeaponAmmo[iWeapon])return;
	else if(IsValidAmmo(Mode,iWeapon))gClientData[client].WeaponAmmo[iWeapon]=Mode;
	else return;
	
	if(!gClientData[client].WeaponAmmo[iWeapon])
		Chat(client,"当前子弹 : 普通子弹");
	else if(gClientData[client].AmmoNum[gClientData[client].WeaponAmmo[iWeapon]]>0 && IsValidAmmo(gClientData[client].WeaponAmmo[iWeapon],iWeapon)){
			AmmoData ammodata;
			GetAmmoByIndex(gClientData[client].WeaponAmmo[iWeapon],ammodata);
			Chat(client,"当前子弹 : %s , 剩余数量 %d 枚",ammodata.Name,gClientData[client].AmmoNum[gClientData[client].WeaponAmmo[iWeapon]]);
		}
	else ToggleModeOfAmmo(client);	
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
		strcopy(string(data.Key),sSecName);
		kv.GetString("m_Name", string(data.Name),"NULL");
		kv.GetString("m_Description", string(data.Description),"NULL");
		data.Price=kv.GetNum("m_Price",0);
		data.BuyMode=view_as<BuyMode>(kv.GetNum("m_BuyMode",0));
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

void ShowMenuStore(int client){
	if(!IsPlayerExist(client))return;
	Menu menu=new Menu(MenuStoreHandle);
	menu.SetTitle("[子弹商店]");
	menu.ExitButton=true;
	Dbg("%d",gServerData.roundstate);
	if(gServerData.roundstate==RoundState_InRound){
		int weaponid=ToolsGetWeaponDefIndex(ToolsGetActiveWeapon(client));
		for(int i=1;i<=gServerData.AmmoMap.Size;i++){
			AmmoData ammo;
			GetAmmoByIndex(i,ammo);
			if(view_as<bool>((view_as<int>(gServerData.roundstate)&view_as<int>(ammo.BuyMode)))&&ammo.AllowedWeapon.FindValue(weaponid)!=-1){
				char info[NORMAL_LINE_LENGTH],display[NORMAL_LINE_LENGTH];
				Format(string(info),"%d|%d|1",i,ammo.Price);
				Dbg(info);
				Format(string(display),"%s : %d$/枚",ammo.Name,ammo.Price);
				menu.AddItem(info,display);
				Dbg("Added");
			}
		}
	}
	else {
		int weapon1=ToolsGetWeaponDefIndex(GetPlayerWeaponSlot(client,0));
		int weapon2=ToolsGetWeaponDefIndex(GetPlayerWeaponSlot(client,1));
		Dbg("%d %d",weapon1,weapon2);
		for(int i=1;i<=gServerData.AmmoMap.Size;i++){
			AmmoData ammo;
			GetAmmoByIndex(i,ammo);
			if(view_as<bool>((view_as<int>(gServerData.roundstate)&view_as<int>(ammo.BuyMode)))&&(ammo.AllowedWeapon.FindValue(weapon1)!=-1||ammo.AllowedWeapon.FindValue(weapon2)!=-1)){
				char info[NORMAL_LINE_LENGTH],display[NORMAL_LINE_LENGTH];
				Format(string(info),"%d|%d|%d",i,ammo.Price*ammo.OneGrp,ammo.OneGrp);
				Dbg(info);
				Format(string(display),"%s : %d$/组 (%d枚/组 <-> %d$/枚)",ammo.Name,ammo.Price*ammo.OneGrp,ammo.OneGrp,ammo.Price);
				menu.AddItem(info,display);
				Dbg("Added");
			}
		}
	}
	menu.Display(client,0);
	Dbg("Shown");
	
}

//-------------------------- Callback Of SDKhook--------------------------------
public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]){
	if(!IsPlayerExist(attacker)||!IsPlayerExist(victim))return Plugin_Continue;
	int weaponid=ToolsGetWeaponDefIndex(weapon);
	if(!IsFirableWeapon(weaponid))return Plugin_Continue;
	AmmoData ammo;
	if(!GetAmmoByIndex(gClientData[attacker].WeaponAmmo[weaponid],ammo))return Plugin_Continue;
	gServerData.RespondDamage=damage;
	gForward._OnTakeDamage(victim, attacker, damage, weapon, damageForce, ammo.Key);
	damage=gServerData.RespondDamage;
	return Plugin_Changed;
}

//-------------------------- Callback Of hookevent--------------------------------
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
	if(!IsPlayerExist(client))return;
	int iWeapon=gClientData[client].LastWeapon;

	if (!IsFirableWeapon(iWeapon))return;

	float vpos[3];
	vpos[0]=event.GetFloat("x");
	vpos[1]=event.GetFloat("y");
	vpos[2]=event.GetFloat("z");
	if(gClientData[client].Hit){
		gClientData[client].Hit=false;
		if(!gClientData[client].WeaponAmmo[iWeapon])return;
		AmmoData ammo;
		if(!GetAmmoByIndex(gClientData[client].WeaponAmmo[iWeapon],ammo))return;
		gForward._OnBulletFire(client,iWeapon,vpos,ammo.Key);
		if(--gClientData[client].AmmoNum[gClientData[client].WeaponAmmo[iWeapon]] == 0)ToggleModeOfAmmo(client,0);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
	gServerData.roundstate=RoundState_InFreezeTime;
}

public Action Event_FreezeEnd(Event event, const char[] name, bool dontBroadcast){
	gServerData.roundstate=RoundState_InRound;
}

//-------------------------- Callback Of Native --------------------------------
public int Native_PostDamage(Handle plugin, int numParams){
	gServerData.RespondDamage=GetNativeCell(1);
}


//-------------------------- Functions Of Auxiliary --------------------------------

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

bool IsValidAmmo(int index,int weapon=-1){
	AmmoData ammo;
	if(!GetAmmoByIndex(index,ammo))return false;
	if(weapon==-1)return true;
	if(ammo.AllowedWeapon.FindValue(weapon)!=-1)return true;
	return false;
}

int ReadAt(char[] str,int &pos){
	int ret=0;
	while(!IsCharNumeric(str[pos]))pos++;
	while(IsCharNumeric(str[pos]))ret=ret*10+(str[pos]^48),pos++;
	return ret;
}

void Dbg(const char[] format, any ...){
	if(gServerData.dbgmode){
		char buf[NORMAL_LINE_LENGTH];
		VFormat(string(buf), format, 2);
		ChatAll(buf);
	}
}
//-------------------------- Handles of menu -------------------------------------------
public int MenuStoreHandle(Menu menu, MenuAction action, int param1, int param2) {
	if (action==MenuAction_Select){
		int client=param1;
		char info[NORMAL_LINE_LENGTH];
		menu.GetItem(param2,string(info));
		Dbg(info);
		int pos=0;
		int index=ReadAt(info,pos),money=ReadAt(info,pos),grpnum=ReadAt(info,pos);
		Dbg("%d %d %d",index,money,grpnum);
		AmmoData ammo;
		GetAmmoByIndex(index,ammo);
		int playermoney=ToolsGetMoney(client);
		if(playermoney>=money){
			Chat(client,"购买 %s * %d 成功!",ammo.Name,grpnum);
			if(gClientData[client].AmmoNum[index]==0){
				Chat(client,"介绍：%s",ammo.Description);
			}
			ToolsSetMoney(client,playermoney-money);
			gClientData[client].AmmoNum[index]+=grpnum;
		}
		else {
			PrintToChat(client,"资金不足,购买失败");
		}
		ShowMenuStore(client);
	}
	else if (action==MenuAction_End){
		CloseHandle(menu);
	}
}


//-------------------------- Functions Of Call Console Command --------------------------------
public Action cmd_toggle_ammo(int client, int args) {
	if(!IsPlayerExist(client))return;
	ToggleModeOfAmmo(client);
}

public Action cmd_call_store(int client, int args){
	if(!IsPlayerExist(client))return;
	Dbg("%d call store",client);
	ShowMenuStore(client);
}

public Action cmd_debug_mode(int client,int args){
	gServerData.dbgmode=true;
}

