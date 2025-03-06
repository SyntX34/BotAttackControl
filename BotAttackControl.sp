#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "Block Bots from Shooting",
	author = "+SyntX",
	description = "Prevents bots from shooting until zombies appear.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/SyntX34"
};

bool g_bZombiesExist = false;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

	// Hook PreThink for all bots
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i))
		{
			SDKHook(i, SDKHook_PreThink, OnPreThink);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		SDKHook(client, SDKHook_PreThink, OnPreThink);
	}
}

public void OnMapStart()
{
	g_bZombiesExist = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bZombiesExist = false;
	CheckForZombies();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bZombiesExist = false;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	g_bZombiesExist = true;
}

public int ZR_OnClientHumanPost(int client, bool respawn, bool protect)
{
	CheckForZombies();
}

public void OnPreThink(int client)
{
	if (!g_bZombiesExist && IsFakeClient(client))
	{
		// Block bot shooting by preventing weapon firing
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (weapon != -1)
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.0);
			SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 1.0);
		}
	}
}

void CheckForZombies()
{
	if (g_bZombiesExist)
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i))
		{
			g_bZombiesExist = true;
			return;
		}
	}

	g_bZombiesExist = false;
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client));
}