#include <laper32>

#define MAXN 256
#define WEAPONMAX 80

#define AmmoType(%1) ClientData[%1].ammotype[GetClientActiveWeapon(%1)]
#define AmmoNumNow(%1) ClientData[%1].ammonum[AmmoType(%1)]

static int AmmoCount=0;

public Plugin myinfo={
	name= "MagicAmmo",
	author= "XmmShp",
	description= "A test plugin",
	version= "1.1",
	url=""
};

enum struct StDataAmmo{
	char Name[MAXN];
	int CanUse[WEAPONMAX];
	int Prize;
	void Init(){
		for(int i=0;i<WEAPONMAX;i++)
			this.CanUse[i]=0;
	}
	void Active(int p){this.CanUse[p]=1;}
}
StDataAmmo Ammo[MAXN];

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

stock int GetClientMoney(int client){
    return GetEntProp(client, Prop_Send, "m_iAccount");
}

stock void SetClientMoney(int client,int val){
	SetEntProp(client, Prop_Send, "m_iAccount", val);
}

void myAdd(int &x,int val,int Mod){
	x=x+val;
	if(x>Mod)x=0;
	else if(x<0)x=Mod;
}

stock bool ExistAmmo(int index){
	return index<=AmmoCount && index >=0;
}

void InitAmmo(){
	Ammo[++AmmoCount].Name="手工子弹[手枪]";
	Ammo[AmmoCount].Prize=15;
	Ammo[AmmoCount].Active(ItemDef_Glock);
	Ammo[AmmoCount].Active(ItemDef_Elite);
	Ammo[AmmoCount].Active(ItemDef_FiveSeven);
	Ammo[AmmoCount].Active(ItemDef_USP);
	Ammo[AmmoCount].Active(ItemDef_Deagle);
	Ammo[AmmoCount].Active(ItemDef_TEC9);
	Ammo[AmmoCount].Active(ItemDef_P250);
	Ammo[AmmoCount].Active(ItemDef_CZ75A);
	Ammo[AmmoCount].Active(ItemDef_HKP2000);
	Ammo[AmmoCount].Active(ItemDef_Revolver);
//----------------------------------------------
	
}

stock int GetClientActiveWeapon(int client){
	char buf[MAXN],bf2[MAXN];
	GetClientWeapon(client,buf,sizeof(buf));
	CS_GetTranslatedWeaponAlias(buf,bf2,sizeof(bf2));
	int weaponid=CS_WeaponIDToItemDefIndex(CS_AliasToWeaponID(bf2));
	return weaponid;
}

public void OnPluginStart(){
	InitAmmo();
	for(int i=0;i<MAXN;i++)ClientData[i].Init();
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_spawned",Event_PlayerSpawn);
	HookEvent("player_death",Event_PlayerDeath);
	RegConsoleCmd("Mgc_Ammo",Command_BuyAmmo);
	RegConsoleCmd("Mgc_Toggle",Command_Toggle);
}

void ToggleMode(int client,int Mode=-1){
	if(!IsPlayerExist(client))return;
	int weaponid=GetClientActiveWeapon(client);
	if(IsProjectile(weaponid)||IsKnife(weaponid))return;
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
	else ToggleMode(client);	
}

public int FreezeMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
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

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast) {
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(!IsPlayerExist(client))return;
	if(AmmoType(client) && AmmoNumNow(client)){
		AmmoNumNow(client)--;
		if(!AmmoNumNow(client)){
			PrintToChat(client,"你的%s已经消耗光了！",Ammo[AmmoType(client)].Name);
			ToggleMode(client,0);
		}
	}
}

public Action Event_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]){
	if(!IsPlayerExist(attacker)||!IsPlayerExist(victim))return Plugin_Continue;
	if(IsKnife(weapon)||IsProjectile(weapon))return Plugin_Continue;
	if(!ClientData[attacker].ammotype[weapon])return Plugin_Continue;
	switch(ClientData[attacker].ammotype[weapon]){
		case 1:{
			damage=damage*1.2;
			PrintToChat(attacker,"使用手工子弹！伤害x1.2！");
		}
	}
	return Plugin_Changed;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(!IsPlayerExist(client,0))
		return;
	SDKHook(client,SDKHook_OnTakeDamage,Event_OnTakeDamage);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(!IsPlayerExist(client,0))
		return;
	ClientData[client].Init();
	SDKUnhook(client,SDKHook_OnTakeDamage,Event_OnTakeDamage);
}


void ShowFreezeMenu(int client){
	if(!IsPlayerExist(client))return;
	int weaponid=GetClientActiveWeapon(client);
	if(IsProjectile(weaponid)||IsKnife(weaponid)){
		PrintToChat(client,"请手持可装配特殊子弹的武器呼出菜单！");
		return;
	}
    Menu menu = new Menu(FreezeMenuHandler, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
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

public Action Command_BuyAmmo(int client, int args) {
	if(!IsPlayerExist(client))return;
	ShowFreezeMenu(client);
}

public Action Command_Toggle(int client, int args) {
	if(!IsPlayerExist(client))return;
	ToggleMode(client);
}