#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

public Plugin myinfo =
{
	name = "[L4D2] Restore Survivor Ragdolls",
	author = "caoqt",
	description = "Creates ragdolls on death for survivors.",
	version = "0.2",
	url = ""
};

Handle g_hCreateServerRagdoll;
DynamicDetour g_hEventKilledDetour;

public void OnPluginStart()
{
	GameData hGameConf = new GameData("l4d2_cs_ragdolls");
	if (hGameConf == null) {
		SetFailState("No l4d2_cs_ragdolls gamedata found");
	}
	
	g_hEventKilledDetour = DynamicDetour.FromConf(hGameConf, "CTerrorPlayer::Event_Killed");
	if (g_hEventKilledDetour == null) {
		SetFailState("Failed to setup detour for CTerrorPlayer::Event_Killed");
	}
	if (!g_hEventKilledDetour.Enable(Hook_Pre, OnPlayerEventKilled)) {
		SetFailState("Failed to enable a pre detour CTerrorPlayer::Event_Killed");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CCSPlayer::CreateRagdollEntity");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hCreateServerRagdoll = EndPrepSDKCall();

}

public void OnEntityCreated (int entity, const char[] name)
{
	if (strcmp(name, "survivor_death_model") == 0)
		SetEntityRenderMode(entity, RENDER_NONE);
}

public MRESReturn OnPlayerEventKilled(int client, DHookParam hParams)
{
	Address g_iDmgInfo = hParams.Get(1);
	SDKCall(g_hCreateServerRagdoll, client, g_iDmgInfo);
	
	return MRES_Ignored;
}