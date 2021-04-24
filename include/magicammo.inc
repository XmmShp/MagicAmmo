#if defined _magicammo_included
    #endinput
#endif

#define _magicammo_included

forward void MagicAmmo_OnTakeDamage(int victim, int attacker,float damage, int weapon, float damageForce[3], char ammoname[]);

forward void MagicAmmo_OnBulletFire(int client, int weapon, float vpos[3],char ammoname[]);

native void MagicAmmo_PostDamage(float damage);