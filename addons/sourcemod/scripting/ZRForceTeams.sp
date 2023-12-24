#include <cstrike>
#include <sdktools>
#include <zombiereloaded>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ZR] Force Teams",
	author = "KiKiEEKi | NZ",
	version = "( PRIVATE 1.0 )"
};

bool g_bStart;
bool g_bWarmup;
int g_iScore[2];

public void OnPluginStart() {
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	AddCommandListener(Command_JoinTeam, "jointeam"); 
}

Action Command_JoinTeam(int iClient, const char[] command, int argc) {
	char sTeam[4];
	GetCmdArg(1, sTeam, sizeof(sTeam));
	if(StringToInt(sTeam) == 2) {
		CS_SwitchTeam(iClient, 3);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason) {
	if(!g_bWarmup) {
		CreateTimer(1.0, Timer_Start, _, TIMER_FLAG_NO_MAPCHANGE);
		if(reason == CSRoundEnd_GameStart || reason == CSRoundEnd_Draw) {
			if(GetTeamClientCount(2) + GetTeamClientCount(3) > 2) {
				return Plugin_Handled;
			}
		}
	}
	else g_bWarmup = false;
	return Plugin_Continue;
}

public void OnMapStart() {
	char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	if(StrContains(sMap, "ze_") != -1) g_bWarmup = true;
	else g_bWarmup = false;
	g_bStart = false;
	g_iScore[0] = 0;
	g_iScore[1] = 0;
	ServerCommand("mp_ignore_round_win_conditions 0");
	ServerCommand("mp_autoteambalance 0");
}

Action Timer_Start(Handle timer, int iUserId) {
	g_bStart = false;
	g_iScore[0] = GetTeamScore(2);
	g_iScore[1] = GetTeamScore(3);
	return Plugin_Continue;
}

Action Event_PlayerSpawn(Event hEvent, const char[] sEvName, bool bDontBroadcast) {
	if(g_bStart) return Plugin_Continue;
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(GetClientTeam(iClient) == 2) CS_SwitchTeam(iClient, 3);
	return Plugin_Continue;
}

Action Timer_Score(Handle timer, int iUserId) {
	SetTeamScore(2, g_iScore[0]);
	SetTeamScore(3, g_iScore[1]);
	return Plugin_Continue;
}

Action Event_RoundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast) {
	g_bStart = false;
	CreateTimer(1.0, Timer_Score, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

Action Event_RoundEnd(Event hEvent, const char[] sEvName, bool bDontBroadcast) {
	CreateTimer(1.0, Timer_Start, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn) {
	g_bStart = true;
}
