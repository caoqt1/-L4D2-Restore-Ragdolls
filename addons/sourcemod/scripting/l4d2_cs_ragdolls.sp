#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define PLUGIN_NAME "[L4D2] Survivor Ragdolls"
#define PLUGIN_AUTHOR "caoqt"
#define PLUGIN_DESC "Ragdolls survivors on death."
#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = ""
};

Handle g_hCreateClientsideRagdoll;
DynamicDetour g_hEventKilledDetour;

ConVar sm_ragdoll_remove;
bool g_bRemove;

public void OnPluginStart()
{
	sm_ragdoll_remove = CreateConVar("survivor_deathmodel_remove", "0");
	sm_ragdoll_remove.AddChangeHook(OnConVarChanged);
	g_bRemove = sm_ragdoll_remove.BoolValue;
	
	AutoExecConfig(true, "l4d2_cs_ragdolls");
	
	GameData hGameConf = new GameData("l4d2_cs_ragdolls");
	if (hGameConf == null) {
		SetFailState("No l4d2_cs_ragdolls gamedata found");
	}
	
	g_hEventKilledDetour = DynamicDetour.FromConf(hGameConf, "CTerrorPlayer::Event_Killed");
	if (g_hEventKilledDetour == null) {
		SetFailState("Failed to setup detour for CTerrorPlayer::Event_Killed");
	}
	else if (!g_hEventKilledDetour.Enable(Hook_Pre, OnPlayerEventKilled)) {
		SetFailState("Failed to enable a pre detour CTerrorPlayer::Event_Killed");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CCSPlayer::CreateRagdollEntity");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hCreateClientsideRagdoll = EndPrepSDKCall();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bRemove = sm_ragdoll_remove.BoolValue;
}

public void OnEntityCreated(int entity, const char[] name)
{
	// Death model logic
	if (strcmp(name, "survivor_death_model") == 0)
	{
		if (g_bRemove)
			RemoveEntity(entity);
		else SetEntityRenderMode(entity, RENDER_NONE);
	}
}

public MRESReturn OnPlayerEventKilled(int iClient, DHookParam hParams)
{
	Address g_iDmgInfo = hParams.Get(1);
	
	// We only need to do this for survivors, not for infected.
	if (GetClientTeam(iClient) == 2)
		SDKCall(g_hCreateClientsideRagdoll, iClient, g_iDmgInfo);
	
	return MRES_Ignored;
}
