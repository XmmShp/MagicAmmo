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

enum struct StServerData{
	int iAmmoCount;
}
StServerData ServerData;

stock int GetClientMoney(int client){
	return GetEntProp(client, Prop_Send, "m_iAccount");
}

stock void SetClientMoney(int client,int val){
	SetEntProp(client, Prop_Send, "m_iAccount", val);
}

stock float Max(float a,float b){return a>b?a:b;}

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
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_Glock));
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_Elite));
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_FiveSeven));
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_USP));
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_Deagle));
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_TEC9));
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_P250));
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_CZ75A));
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_HKP2000));
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_Revolver));
//----------------------------------------------
	Ammo[++AmmoCount].Name="推进子弹[Scout]";
	Ammo[AmmoCount].Prize=450;
	Ammo[AmmoCount].Active(view_as<int>(ItemDef_SSG08));
/* 
JSON

{
	"AmmoType": {
		{
			"m_ammoName": "${ammoName}",
			"m_ammoPrice": "${ammoPrice}",
			"m_availableWeapon": [
				"weapon_m4a1", "weapon_${Arbitrary}"
			]
			"callback":"${funcName}"
		}
	}
}

forward OnBulletFired()

GetFunctionByName(GetMyHandle(), "${funcCallback}");

 */	
}

stock int GetClientActiveWeapon(int client){
	char buf[MAXN],bf2[MAXN];
	GetClientWeapon(client,buf,sizeof(buf));
	CS_GetTranslatedWeaponAlias(buf,bf2,sizeof(bf2));
	int weaponid=CS_WeaponIDToItemDefIndex(CS_AliasToWeaponID(bf2));
	return weaponid;
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

void ToggleMode(int client,int Mode=-1){
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

void CheckOnAmmoRemain(int client){
	if(!IsPlayerExist(client))return;
	if(!AmmoNumNow(client))ToggleMode(client,0);
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

public Action Event_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]){
	if(!IsPlayerExist(attacker)||!IsPlayerExist(victim))return Plugin_Continue;
	int weaponid=GetClientActiveWeapon(attacker);
	if(IsKnife(view_as<ItemDef>(weaponid))||IsProjectile(view_as<ItemDef>(weaponid)))return Plugin_Continue;
	if(!ClientData[attacker].ammotype[weaponid])return Plugin_Continue;
	switch(ClientData[attacker].ammotype[weaponid]){
		case 1:{
			damage=damage*1.2;
			PrintToChat(attacker,"使用手工子弹！伤害x1.2！");
		}
		case 2:{
			float Vel[3],Cop[3];
			Cop[0]=damageForce[0];Cop[1]=damageForce[1];Cop[2]=0.0;
			VecShorten(Cop,Vel,MAXSPEED*2.0);
			Vel[2]=Max(MAXSPEED*2+1.0,damageForce[2]);
			// PrintToChat(attacker,"%f %f %f:%f %f %f",damageForce[0],damageForce[1],damageForce[2],Vel[0],Vel[1],Vel[2]);
			ToolsSetVelocity(victim,Vel);
			PrintToChat(attacker,"使用推进子弹！对敌人造成击退！");
		}
	}
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
	if(!IsPlayerExist(client,false))
		return;
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

public Action Command_BuyAmmo(int client, int args) {
	if(!IsPlayerExist(client))return;
	ShowFreezeMenu(client);
}

public Action Command_Toggle(int client, int args) {
	if(!IsPlayerExist(client))return;
	ToggleMode(client);
}