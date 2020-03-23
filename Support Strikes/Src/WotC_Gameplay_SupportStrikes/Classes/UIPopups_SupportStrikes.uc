
// This is a short class that instantates a popup screen using OnActiveUnitChanged event
class UIPopups_SupportStrikes extends Object
	implements(X2VisualizationMgrObserverInterface) config (Game);

var config string SINGLETON_PATH;

var bool bPopupShown;

//
// Borrowed from robojumper's Post Process Status Effects
//
static function UIPopups_SupportStrikes GetOrCreate()
{
	local UIPopups_SupportStrikes LocalObserver;
	
	LocalObserver = UIPopups_SupportStrikes(FindObject(default.SINGLETON_PATH, default.Class));
	if (LocalObserver == none) {
		LocalObserver = new default.Class;
		LocalObserver.Init();
		default.SINGLETON_PATH = PathName(LocalObserver);
	}
	return LocalObserver;
}

function Init()
{
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

}

//
// Visualization Stuff
//

event OnVisualizationBlockComplete(XComGameState AssociatedGameState);
event OnVisualizationIdle();
event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{
	local XComPresentationLayer								Pres;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;
	local TDialogueBoxData									kData;

	if ( `XENGINE.IsSinglePlayerGame() && 
		!(`ONLINEEVENTMGR.bIsChallengeModeGame) && 
		!class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true) )
	{
		if (!bPopupShown)
		{
			Pres = `PRES;
			SupportStrikeMgr = XComGameState_SupportStrikeManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

			if (SupportStrikeMgr != none)
			{
				if (SupportStrikeMgr.bInvalid_HeightClearance)
				{
					// Report to the player that the site is invalid for support strikes
					kData.eType     = eDialog_Alert;
					kData.strTitle  = class'UIAlert_SupportStrikes'.default.strTitle_Error_StrikeNotAvaliable;
					kData.strText   = class'UIAlert_SupportStrikes'.default.strDesc_Reason_MissionSiteInvalid;
					kData.strAccept = Pres.m_strOK;

					Pres.UIRaiseDialog( kData );	

					bPopupShown = true;
				}

				if (SupportStrikeMgr.bValid)
				{
					Pres.UITutorialBox( class'UIAlert_SupportStrikes'.default.strTitle_Ready_StrikeAvaliable, 
					class'UIAlert_SupportStrikes'.default.strDesc_Ready_StrikeAvaliable, "" );

					bPopupShown = true;
				}
			}
		}
	}
}
