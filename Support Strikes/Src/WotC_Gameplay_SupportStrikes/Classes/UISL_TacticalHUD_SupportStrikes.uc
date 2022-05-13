class UISL_TacticalHUD_SupportStrikes extends UIScreenListener;

event OnInit(UIScreen Screen) {

    if (UITacticalHUD(Screen) == none) 
		return; 

	class'UIPopups_SupportStrikes'.static.GetOrCreate();

	// Spawn Alpha Smoke Pathing visualization if set in config
	if (class'X2Ability_MortarStrikes'.default.bEnableSmokeTileVisualization)
		`XWORLDINFO.Spawn(class'SmokeMortarTileListener');
}