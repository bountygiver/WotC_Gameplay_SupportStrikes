class X2DownloadableContentInfo_WotC_SupportStrikes extends X2DownloadableContentInfo;

var config bool bLog;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{

}

static event OnLoadedSavedGameToStrategy()
{

}
