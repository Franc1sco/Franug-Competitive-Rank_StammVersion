#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <stamm>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

int g_iRank[MAXPLAYERS+1] = {0,...};

public Plugin myinfo = {
	name = "[CS:GO] Competitive Ranks - Stamm version",
	author = "Franc1sco franug",
	description = "Show competitive ranks and coins on scoreboard",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}
	STAMM_LoadTranslation();
	STAMM_RegisterFeature("Competitive Ranks");
}

// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetRanks", client);
	
	PushArrayString(array, fmt);
}

public void OnPluginStart()
{
	
	HookEvent("announce_phase_end", Event_AnnouncePhaseEnd);
}

public void OnMapStart()
{
	int iIndex = FindEntityByClassname(MaxClients+1, "cs_player_manager");
	if (iIndex == -1)
	{
		SetFailState("Unable to find cs_player_manager entity");
	}
	SDKHook(iIndex, SDKHook_ThinkPost, Hook_OnThinkPost);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_SCORE && !(GetEntProp(client, Prop_Data, "m_nOldButtons") & IN_SCORE)) {
		UpdateRanks();
		Handle hBuffer = StartMessageOne("ServerRankRevealAll", client);
		if (hBuffer == INVALID_HANDLE)
		{
			PrintToChat(client, "INVALID_HANDLE");
		}
		else
		{
			EndMessage();
		}
	}
	return Plugin_Continue;
}

public Action Event_AnnouncePhaseEnd(Handle event, const char[] name, bool dontBroadcast)
{
	UpdateRanks();
	Handle hBuffer = StartMessageAll("ServerRankRevealAll");
	if (hBuffer == INVALID_HANDLE)
	{
		PrintToServer("ServerRankRevealAll = INVALID_HANDLE");
	}
	else
	{
		EndMessage();
	}
	return Plugin_Continue;
}

public void Hook_OnThinkPost(int iEnt)
{
	static int Offset = -1;
	if (Offset == -1)
	{
		Offset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");
	}

	SetEntDataArray(iEnt, Offset, g_iRank, MAXPLAYERS+1, _, true);
}

UpdateRanks()
{
	// Client loop
	for (new i = 1; i <= MaxClients; i++)
	{
		// Client valid?
		if (IsClientInGame(i) && STAMM_IsClientValid(i))
		{
			// Get highest client block
			g_iRank[i] = STAMM_GetClientBlock(i);

		}
	}	
}