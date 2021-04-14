#include <laper32>

#define MAXN 256
#define WEAPONMAX 80

#define AmmoType(%1) ClientData[%1].ammotype[GetClientActiveWeapon(%1)]
#define AmmoNumNow(%1) ClientData[%1].ammonum[AmmoType(%1)]
#define AmmoCount ServerData.iAmmoCount

#define MAXSPEED 250

public Plugin myinfo={
	name= "MagicAmmo",
	author= "XmmShp",
	description= "A test plugin",
	version= "1.1",
	url=""
};

/* 
"Section"
{
	"Key"			"Value"
	"NestedSection"
	{
		"NestedKey" "NextedValue"
	}
}
"m_NameTextKey"
{

}

char sName[128];
Format(string(sName), "%t", "pistol_handmaking");

Name + Price + 
 */


enum struct StDataAmmo{
	/*rewrite*/
}

enum struct StDataClient{
	int ammotype[WEAPONMAX];
	int ammonum[MAXN];
	void Init(){
		for(int i=0;i<MAXN;i++)
			this.ammonum[i]=0;
		for(int i=0;i<WEAPONMAX;i++)
			this.ammotype[i]=0;
	}
}
StDataClient ClientData[MAXN];

// enum struct StServerData{
// 	int iAmmoCount;
//  ArrayList m_AmmoData;
// }
// StServerData ServerData;

public void AddAmmoToCFG(/*rewrite*/)

void myAdd(int &x,int val,int Mod){
	x=x+val;
	if(x>Mod)x=0;
	else if(x<0)x=Mod;
}

stock bool ExistAmmo(int index){
	return index<=AmmoCount && index >=0;
}

void InitAmmo(){
/* 
JSON for ammo

{
	"Ammo": {
		{
			"Enabled": "", //Bool:Enable ammo or not
			"Name": "",//String:Ammo's name to display
			"Price": "",//Int:Ammo's prize for per ammo
			"BuyTime": "" //enum String:When can ammo be bought :"All" | "PreRound" | "InRound",
			"GroupNum": "",//Int:If the ammo can be bought in preround,how many ammo's will be bought in once
			"Describe": "",//String:The describe of ammo
			"m_availableWeapon": [
				""
			]//String[]:Weapon name of which weapons can use this ammo
		}
	}
}

Json for armor

{
	"Armor": {
		{
			"Enabled": "",//Bool:Enable armor or not
			"Name": "",//String:Armor's name to display
			"Price": "",//Int:Armor's prize
			"Describe": "",//String:The describe of armor
			"Callback": "",//String:The name of what function to call when apply armor 
		}
	}
}
*/	
/* 

// File: Ammo.json
{
	"Ammo": {
		"Ammo_Type_One": {
			"m_Description": "",
			"m_Enabled": "",
			"m_Price": "",
			"m_BuyTime": "",
			"m_BuyInTime": "",
			"m_AllowedWeapon": [

			]
		}
	}
}

// File: Armor.json
{
	"Armor": {
		"Armor_Type_One": {
			"m_Description": "",
			"m_Enabled": "",
			"m_Price": ""
		}
	}
}

To considering the framework structure, I removed several field which described below: 
"Callback", and "HookMode".

The explanation is below:
In fact, you can export a forward, then write specific script to do things what you want.

To achieve what you want to do, you can do something below:

int GetAmmoIdByName(const char[] name) {
	foreach (i in ArrayList.Ammo) {
		if strEqual(i.m_Name, name) {
			return i;
		}
	}
	// using -1 to represents not found
	return -1;
}

Next, you can do it in your exported file:

int g_iAmmoID;

public void OnLibraryAdded(const char[] name) {
	// check your library, then execute it, for example, set ID, etc.
	// Next, to do things what you want.
}

// We make an example here, for example, takeDamage

public void func_OnTakeDamage(int client, int attacker, int weaponID) {
	ArrayList list = ammo.GetAllowedWeapons();
	if list.Find(g_iAmmoID)  {
		// execute take damage, or something what you want.
	}
}


*/

}

stock int GetClientActiveWeapon(int client){//
	/*
	rewrite
	*/
}

stock void VecShorten(float vs[3],float vr[3],float val){
	float len=GetVectorLength(vs);
	float rate=val/len;
	vr[0]=vs[0]*rate;
	vr[1]=vs[1]*rate;
	vr[2]=vs[2]*rate;
}

public void OnPluginStart(){
	AmmoCount=0;
	InitAmmo();
	for(int i=0;i<MAXN;i++)ClientData[i].Init();
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_death",Event_PlayerDeath);
	HookEvent("round_start",Event_RoundStart);
	HookEvent("player_hurt",Event_PlayerHurt);
	HookEvent("round_end",Event_RoundEnd)
	RegConsoleCmd("Mgc_Ammo",Command_BuyAmmo);
	RegConsoleCmd("Mgc_Toggle",Command_Toggle);
}

void ToggleModeOfAmmo(int client,int Mode=-1){
	if(!IsPlayerExist(client))return;
	int weaponid=GetClientActiveWeapon(client);
	if(IsProjectile(view_as<ItemDef>(weaponid))||IsKnife(view_as<ItemDef>(weaponid)))return;
	if(Mode==-1){
		myAdd(AmmoType(client),1,AmmoCount);
	}
	else if(Mode==AmmoType(client))return;
	else if(ExistAmmo(Mode))AmmoType(client)=Mode;
	else return;
	
	if(!AmmoType(client)||(AmmoNumNow(client)&&Ammo[AmmoType(client)].CanUse[GetClientActiveWeapon(client)])){
		if(AmmoType(client))
			PrintToChat(client,"当前子弹 : %s , 剩余数量 %d 枚",Ammo[AmmoType(client)].Name,AmmoNumNow(client));
		else 
			PrintToChat(client,"当前子弹 : 普通子弹");
		return;
	}
	else ToggleModeOfAmmo(client);	
}

//ToggleModeOfArmor

public int FreezeMenuHandler(Menu menu, MenuAction action, int param1, int param2) {//rewrite
	if (action==MenuAction_Select) {
		int client=param1;
		char info[MAXN];
		menu.GetItem(param2,info,sizeof(info));
		int index = StringToInt(info);
		if(GetClientMoney(client)>=Ammo[index].Prize){
			ClientData[client].ammonum[index]++;
			SetClientMoney(client, GetClientMoney(client) - Ammo[index].Prize);
		}
		else {
			PrintToChat(client,"你没有足够的金钱购买 %s !",Ammo[index].Name);
		}
	} 
	else if(action == MenuAction_End) {
		CloseHandle(menu);
	}
}

void CheckOnAmmoRemain(int client){
	if(!IsPlayerExist(client))return;
	if(!AmmoNumNow(client))ToggleModeOfAmmo(client,0);
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast) {
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(!IsPlayerExist(client))return;
	int weaponid=GetClientActiveWeapon(client);
	if(IsKnife(view_as<ItemDef>(weaponid))||IsProjectile(view_as<ItemDef>(weaponid)))return;
	if(AmmoType(client) && AmmoNumNow(client)){
		AmmoNumNow(client)--;
		if(!AmmoNumNow(client)){
			PrintToChat(client,"你的 %s 已经消耗光了！",Ammo[AmmoType(client)].Name);
		}
	}
}

public Action Event_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]){//rewrite
	if(!IsPlayerExist(attacker)||!IsPlayerExist(victim))return Plugin_Continue;
	//Callback of Armor
	int weaponid=GetClientActiveWeapon(attacker);
	if(IsKnife(view_as<ItemDef>(weaponid))||IsProjectile(view_as<ItemDef>(weaponid)))return Plugin_Changed;
	if(!ClientData[attacker].ammotype[weaponid])return Plugin_Changed;
	/*
	Callback of Ammo
	*/
	return Plugin_Changed;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	for(int i=1;i<=MaxClients;i++)
		if(IsPlayerExist(i)){
			// PrintToChatAll("Hook Entity %d:%N",i,i);
			SDKHook(i,SDKHook_OnTakeDamage,Event_OnTakeDamage);
		}
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int client=GetClientOfUserId(event.GetInt("userid"));
	int attacker=GetClientOfUserId(event.GetInt("attacker"));
	if(!IsPlayerExist(client)||!IsPlayerExist(attacker))return;
	CheckOnAmmoRemain(attacker);
	//PrintToChatAll("%N:%d",client,event.GetInt("dmg_health"));
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	for(int i=1;i<=MaxClients;i++)
		if(IsPlayerExist(i,false)){
			// PrintToChatAll("UnHook Entity %d:%N",i,i);
			SDKUnhook(i,SDKHook_OnTakeDamage,Event_OnTakeDamage);
		}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(!IsPlayerExist(client,false))return;
	ClientData[client].Init();
}


void ShowFreezeMenu(int client){
	if(!IsPlayerExist(client))return;
	int weaponid=GetClientActiveWeapon(client);
	if(IsProjectile(view_as<ItemDef>(weaponid))||IsKnife(view_as<ItemDef>(weaponid))){
		PrintToChat(client,"请手持可装配特殊子弹的武器呼出菜单！");
		return;
	}
	Menu menu = new Menu(FreezeMenuHandler);
	menu.SetTitle("[特殊子弹商店]\n ");
	char display[MAXN],Tmp[MAXN];
	for(int i = 1; i <= AmmoCount; i++)
	if(Ammo[i].CanUse[weaponid]){
		IntToString(i,Tmp,sizeof(Tmp));
		Format(display,sizeof(display),"%s [%d $ / 枚]",Ammo[i].Name,Ammo[i].Prize);
		menu.AddItem(Tmp, display);
	}
	menu.ExitButton = true;
	menu.Display(client,0);
}

//ShowMenu in round
public Action Command_BuyAmmo(int client, int args) {
	if(!IsPlayerExist(client))return;
	ShowFreezeMenu(client);
}

public Action Command_Toggle(int client, int args) {
	if(!IsPlayerExist(client))return;
	ToggleModeOfAmmo(client);
}

/**
 * @brief Converts string of "yes/on", "no/off", "false/true", "1/0" to a boolean value.  Always uses english as main language.
 * 
 * @param sOption           The string to be converted.
 * @return                  True if string is "yes", false otherwise.
 **/
stock bool ConfigSettingToBool(char[] sOption)
{
	// If option is equal to "yes", then return true
	if (!strcmp(sOption, "yes", false) || !strcmp(sOption, "on", false) || !strcmp(sOption, "true", false) || !strcmp(sOption, "1", false))
	{
		return true;
	}
	
	// Option isn't yes
	return false;
}