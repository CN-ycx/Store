#define Module_Neon

enum struct Neon
{
    int iColor[4];
    int iBright;
    int iDistance;
    int iFade;
}

static Neon g_eNeons[STORE_MAX_ITEMS];
static int g_iNeons = 0;
static int g_iClientNeon[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

public bool Neon_Config(KeyValues kv, int itemid) 
{ 
    Store_SetDataIndex(itemid, g_iNeons); 
    KvGetColor(kv, "color", g_eHats[g_iNeons].iColor[0], g_eHats[g_iNeons].iColor[1], g_eHats[g_iNeons].iColor[2], g_eHats[g_iNeons].iColor[3]); 
    g_eHats[g_iNeons].iBright = kv.GetNum("brightness");
    g_eHats[g_iNeons].iDistance = kv.GetNum("distance");
    g_eHats[g_iNeons].iFade = kv.GetNum("distancefade");
    ++g_iNeons;
    return true; 
}

public void Neon_OnMapStart()
{
    
}

void Neon_OnClientDisconnect(int client)
{
    Store_RemoveClientNeon(client);
}

public void Neon_Reset()
{
    g_iNeons = 0;
}

public int Neon_Equip(int client, int id)
{
    RequestFrame(EquipNeon_Delay, client);

    return 0;
}

public void EquipNeon_Delay(int client)
{
    if(IsClientInGame(client) && IsPlayerAlive(client))
        Store_SetClientNeon(client);
}

public int Neon_Remove(int client) 
{
    Store_RemoveClientNeon(client);
    return 0; 
}

void Store_RemoveClientNeon(int client)
{
    if(g_iClientNeon[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iClientNeon[client]);
        if(IsValidEdict(entity))
        {
            AcceptEntityInput(entity, "Kill");
        }
        g_iClientNeon[client] = INVALID_ENT_REFERENCE;
    }
}

void Store_SetClientNeon(int client)
{
    Store_RemoveClientNeon(client);

#if defined GM_ZE
    if(g_iClientTeam[client] == 2)
        return;
#endif

    int m_iEquipped = Store_GetEquippedItem(client, "neon", 0); 
    if(m_iEquipped < 0) 
        return;

    int m_iData = Store_GetDataIndex(m_iEquipped);

    if(g_eHats[m_iData].iColor[3] != 0)
    {
        float clientOrigin[3];
        GetClientAbsOrigin(client, clientOrigin);

        int iNeon = CreateEntityByName("light_dynamic");
        
        char m_szString[100];
        IntToString(g_eHats[m_iData].iBright, m_szString, 100);
        DispatchKeyValue(iNeon, "brightness", m_szString);

        FormatEx(m_szString, 100, "%d %d %d %d", g_eHats[m_iData].iColor[0], g_eHats[m_iData].iColor[1], g_eHats[m_iData].iColor[2], g_eHats[m_iData].iColor[3]);
        DispatchKeyValue(iNeon, "_light", m_szString);
        
        IntToString(g_eHats[m_iData].iFade, m_szString, 100);
        DispatchKeyValue(iNeon, "spotlight_radius", m_szString);

        IntToString(g_eHats[m_iData].iDistance, m_szString, 100);
        DispatchKeyValue(iNeon, "distance", m_szString);

        DispatchKeyValue(iNeon, "style", "0");

        SetEntPropEnt(iNeon, Prop_Send, "m_hOwnerEntity", client);

        DispatchSpawn(iNeon);
        AcceptEntityInput(iNeon, "TurnOn");

        TeleportEntity(iNeon, clientOrigin, NULL_VECTOR, NULL_VECTOR);

        SetVariantString("!activator");
        AcceptEntityInput(iNeon, "SetParent", client, iNeon, 0);

        g_iClientNeon[client] = EntIndexToEntRef(iNeon);

        Call_OnNeonCreated(client, iNeon);
    }
}

stock void Call_OnNeonCreated(int client, int entity)
{
    static Handle gf = null;
    if (gf == null)
    {
        // create
        gf = CreateGlobalForward("Store_OnNeonCreated", ET_Ignore, Param_Cell, Param_Cell);
    }

    Call_StartForward(gf);
    Call_PushCell(client);
    Call_PushCell(entity);
    Call_Finish();
}