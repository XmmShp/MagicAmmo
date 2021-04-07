#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#include <smutils>
#include <maaoxm>  

#define AmmoType(i) ClientData[i].ammotype
#define AmmoNum(i,j) ClientData[i].ammonum[j]
#define AmmoNumNow(i) ClientData[i].ammonum[ClientData[i].ammotype]

#define MAXN 0xff
#define M 2048

int AmmoCount=0;

public Plugin myinfo={
	name= "MagicAmmo",
	author= "XmmShp",
	description= "A test plugin",
	version= "0.2",
	url=""
};

struct stDataAmmo{
	char Name[MAXN];
	int CanUse[MAXN];
	void Init(){
		for(int i=0;i<MAXN;i++)
			CanUse[i]=0;
	}
}
stDataAmmo Ammo[MAXN];

struct stDataClient{
	int ammotype;
	int ammonum[M];
	void Init(){
		ammotype=0;
		for(int i=0;i<M;i++)
			ammonum[i]=0;
	}
}
stDataClient ClientData[MAXN];

public void OnPluginStart(){
	for(int i=0;i<MAXN;i++)ClientData[i].Init();
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_spawned",Event_PlayerSpawn);
	HookEvent("player_death",Event_PlayerDeath);
	RegConsoleCmd("Mgc_Ammo",Command_BuyAmmo);
	RegConsoleCmd("Mgc_Toggle",Command_Toggle);
}

void ToggleMode(int client,int Mode=-1){
	if(!IsPlayerExist(client))return;
	if(Mode!=-1)
		myAdd(ClientData[client].ammotype,1,AmmoCount);
	else if(Mode==AmmoType(client))
		return;
	else ClientData[client].ammotype=Mode;
	if(!AmmoType(client)||AmmoNumNow(client)){
		if(AmmoType(i))
			Chat(client,"当前子弹 : %s , 剩余数量 %d 枚",AmmoName[AmmoType(i)],AmmoNumNow(i));
		else 
			Chat(client,"当前子弹 : %s",AmmoName[AmmoType(i)]);
		return;
	}
	else ToggleMode(client);	
}

public int FreezeMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action==MenuAction_Select) {
		int client=param1;
		char info[MAXN];
		menu.GetItem(param2,info,sizeof(info));
		int index = StringToInt(info);
		if(GetClientMoney(client)<AmmoPrize[index]){
			Chat(client,"你没有足够的资金来购买这组弹药！")
		}
		else {
			Chat(client,"%d枚%s已经购买！",AmmoGroup[index],AmmoName[index]);
			SetClientMoney(client,GetClientMoney(client)-AmmoPrize[index]);
			ClientData[client].ammonum[index]+=AmmoGroup[index];
		}
	} 
	else if(action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast) {
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(!IsPlayerExist(client))
	if(AmmoType(client) && AmmoNumNow(client)){
		ClientData[client].ammonum[ClientData[client].ammotype]--;
		if(!AmmoNumNow(client)){
			Chat(client,"你的%s已经消耗光了！",AmmoName[AmmoType(client)]);
			ToggleMode(client,0);
		}
	}
}

public Action Event_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]){
	
	return Plugin_Changed;
}
public Action Event_ChangeWeapon(int client, int weapon){
	
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(!IsPlayerExist(client,0))return;
	SDKHook(client,SDKHook_OnTakeDamage,Event_OnTakeDamage);
	SDKHook(client,SDKHook_WeaponDropPost,Event_ChangeWeapon);
	SDKHook(client,SDKHook_WeaponEquipPost,Event_ChangeWeapon);
	SDKHook(client,SDKHook_WeaponSwitchPost,Event_ChangeWeapon);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(!IsPlayerExist(client,0))return;
	ClientData[client].Init();
	SDKUnHook(client,SDKHook_OnTakeDamage,Event_OnTakeDamage);
	SDKUnHook(client,SDKHook_WeaponDropPost,Event_ChangeWeapon);
	SDKUnHook(client,SDKHook_WeaponEquipPost,Event_ChangeWeapon);
	SDKUnHook(client,SDKHook_WeaponSwitchPost,Event_ChangeWeapon);
}


void ShowFreezeMenu(int client){
	if(!IsPlayerExist(client))return;
    Menu menu = new Menu(FreezeMenuHandler, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
    menu.SetTitle("[特殊子弹商店]\n ");
    char display[1<<10],Tmp[1<<10];
    for(int i = 1; i <= AmmoCount; i++){
		IntToString(i,Tmp,sizeof(Tmp));
		Format(display,sizeof(display),"%s [%d $ / %d 枚]",AmmoName[i],AmmoPrize[i],AmmoGroup[i]);
		menu.AddItem(Tmp, display);
    }
    menu.ExitButton = true;
    menu.Display(client);
}

public Action Command_BuyAmmo(int client, int args) {
	if(!IsPlayerExist(client))return;
	ShowFreezeMenu(client);
}

public Action Command_Toggle(int client, int args) {
	if(!IsPlayerExist(client))return;
	ToggleMode(client);
}