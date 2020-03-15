//
// FILE: X2EventListener_SupportStrikes.uc
// DESC: Tactical Event Listeners that don't belong elsewhere
//

class X2EventListener_SupportStrikes_Tactical extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSupportStrikeTacticalListeners());

	return Templates;
}

static function CHEventListenerTemplate CreateSupportStrikeTacticalListeners()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'SupportStrike_TacticalListener');
	Template.AddCHEvent('OnTacticalBeginPlay', OnTacticalBeginPlay, ELD_OnStateSubmitted, 51);
//	Template.AddCHEvent('PlayerTurnBegun', ShowSupportStrikeMessage, ELD_Immediate, -50);
	Template.RegisterInTactical = true;

	return Template;
}

// Catches the beginning of a mission
// NOTE: This is gonna look real nasty but ensures that everything is correct
static function EventListenerReturn OnTacticalBeginPlay(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory								History;
	local XComGameState										NewGameState;
	local XComGameState_HeadquartersXCom					XComHQ;
	local XComGameState_Unit								UnitState;
	local StateObjectReference								UnitRef;
	local XComPresentationLayer								Pres;
	local TDialogueBoxData									kData;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;
	local name												UnlockName;
	local int												Index;

	if (GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Pres = `PRES;

	// Create a new gamestate since something will be modified
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("X2EventListener_SupportStrikes.OnTacticalBeginPlay");

	SupportStrikeMgr = XComGameState_SupportStrikeManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	// Nothing happens if there's no Support Strike Manager
	if (SupportStrikeMgr == none)
		return ELR_NoInterrupt;

	// If there is no strikes bought, exit listener
	if (SupportStrikeMgr.PurchasedSupportStrikes.Length == 0)
	{
		`LOG("[OnTacticalBeginPlay()] Player has no Strikes." ,,'WotC_Gameplay_SupportStrikes');
		return ELR_NoInterrupt;
	}

	SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

	//
	//		* Check Environment
	//		* Add popup message if strikes are not supported here
	//
	if ( DoesGeneratedMissionHaveInvalidMap(History) )
	{
		`LOG("[OnTacticalBeginPlay()] No Z-level Clearance in map." ,,'WotC_Gameplay_SupportStrikes');
		SupportStrikeMgr.bInvalid_HeightClearance = true;
				
		// Report to the player that the site is invalid for support strikes
		kData.eType     = eDialog_Alert;
		kData.strTitle  = class'UIAlert_SupportStrikes'.default.strTitle_Error_StrikeNotAvaliable;
		kData.strText   = class'UIAlert_SupportStrikes'.default.strDesc_Reason_MissionSiteInvalid;
		kData.strAccept = Pres.m_strOK;

		Pres.UIRaiseDialog( kData );	
	}
	else
	{
		// Check all units in the squad and add the appropriate items
		foreach XComHQ.Squad(UnitRef)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (UnitState != none)
			{
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				foreach SupportStrikeMgr.PurchasedSupportStrikes(UnlockName)
				{
					Index = SupportStrikeMgr.SupportStrikeData.Find('GTSTemplate', UnlockName);
					if (Index != INDEX_NONE)
					{
						class'X2Helpers_MiscFunctions'.static.GiveItem(SupportStrikeMgr.SupportStrikeData[Index].ItemToGive, UnitState, NewGameState);
						`LOG("[OnTacticalBeginPlay()] " $ UnitState.GetFullName() $ " has been given " $ SupportStrikeMgr.SupportStrikeData[Index].ItemToGive,,'WotC_Gameplay_SupportStrikes');
					}
				}
			}
		}

		// Report to the player that the support team is ready for instructions
		// This will eventually be replaced with a Narrative moment

		Pres.UITutorialBox( class'UIAlert_SupportStrikes'.default.strTitle_Ready_StrikeAvaliable, 
		class'UIAlert_SupportStrikes'.default.strDesc_Ready_StrikeAvaliable, "" );
	}

	// If something happened, submit gamestate
	// Otherwise, clean up the gamestate
	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`LOG("[OnTacticalBeginPlay()] Submitted changes to history." ,,'WotC_Gameplay_SupportStrikes');
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

// Repurposed X2Conditon_MapCheck.uc for above event listener
static function bool DoesGeneratedMissionHaveInvalidMap(XComGameStateHistory History)
{
	local XComGameState_BattleData BattleData;
	local PlotDefinition PlotDef;
	local string PlotType;
	local StoredMapData_Parcel ParcelComp;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	PlotDef = `PARCELMGR.GetPlotDefinition(BattleData.MapData.PlotMapName);
	PlotType = PlotDef.strType;

	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Count: Disallowed Biomes: "$ class'X2Condition_MapCheck'.default.DisallowedBiomes.Length $", Disallowed Plots: "$ class'X2Condition_MapCheck'.default.DisallowedPlots.Length $", Disallowed Parcels: "$ class'X2Condition_MapCheck'.default.DisallowedParcels.Length ,class'X2DownloadableContentInfo_WotC_SupportStrikes'.default.bLog,'WotC_Gameplay_SupportStrikes');
	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Biome: " $ BattleData.MapData.Biome,class'X2DownloadableContentInfo_WotC_SupportStrikes'.default.bLog,'WotC_Gameplay_SupportStrikes');
	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Plot Type: " $ PlotType ,class'X2DownloadableContentInfo_WotC_SupportStrikes'.default.bLog,'WotC_Gameplay_SupportStrikes');

	if (class'X2Condition_MapCheck'.default.DisallowedBiomes.Length > 0)
		if (class'X2Condition_MapCheck'.default.DisallowedBiomes.Find(BattleData.MapData.Biome) != INDEX_NONE)
			return true;

	if (class'X2Condition_MapCheck'.default.DisallowedPlots.Length > 0)
		if (class'X2Condition_MapCheck'.default.DisallowedPlots.Find(PlotType) != INDEX_NONE)
			return true;

	if (class'X2Condition_MapCheck'.default.DisallowedParcels.Length > 0)
		foreach BattleData.MapData.ParcelData(ParcelComp)
			if (class'X2Condition_MapCheck'.default.DisallowedParcels.Find(ParcelComp.MapName) != INDEX_NONE)
				return true;

	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Condition Passed",class'X2DownloadableContentInfo_WotC_SupportStrikes'.default.bLog,'WotC_Gameplay_SupportStrikes');
	return false;
}

// Adds additional maps to the game manually
// TODO
function AddStreamingCinematicMaps()
{
/*
	// add the streaming map if we're not at level initialization time
	//	should make this work when using dropUnit etc
	local XComGameStateHistory History;
	local X2CharacterTemplateManager TemplateManager;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit kGameStateUnit;
	local string MapName;

	History = `XCOMHISTORY;
	if (History.GetStartState() == none)
	{

		kGameStateUnit = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));

		TemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
		CharacterTemplate = TemplateManager.FindCharacterTemplate(kGameStateUnit.GetMyTemplateName());
		if (CharacterTemplate != None)
		{
			foreach CharacterTemplate.strMatineePackages(MapName)
			{
				if(MapName != "")
				{
					`MAPS.AddStreamingMap(MapName, , , false).bForceNoDupe = true;
				}
			}
		}

	}
*/
}

//
// TODO: Fix this executing too early in a mission (before the briefing is done)
//
/*
static function EventListenerReturn ShowSupportStrikeMessage(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory								History;
	local XComGameState_HeadquartersXCom					XComHQ;
	local XComPresentationLayer								Pres;
	local TDialogueBoxData									kData;
	local XComGameState_Player								PlayerState;

	PlayerState = XComGameState_Player(EventData);

	if( PlayerState.TeamFlag != eTeam_XCom && PlayerState.PlayerTurnCount != 1)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Pres = `PRES;

	if (XComHQ.GetGenericKeyValue("SupportStrike_InvalidLocation") > -1)
	{
		// Report to the player that the site is invalid for support strikes
		kData.eType     = eDialog_Alert;
		kData.strTitle  = class'UIAlert_SupportStrikes'.default.strTitle_Error_StrikeNotAvaliable;
		kData.strText   = class'UIAlert_SupportStrikes'.default.strDesc_Reason_MissionSiteInvalid;
		kData.strAccept = Pres.m_strOK;

		Pres.UIRaiseDialog( kData );	

		return ELR_NoInterrupt;
	}

	// TODO: Try to make this cleaner 
	if (	(XComHQ.GetGenericKeyValue("SupportStrike_Space_Orbital") > -1)	 ||
			(XComHQ.GetGenericKeyValue("SupportStrike_Arty_Mortar_SMK") > -1) ||
			(XComHQ.GetGenericKeyValue("SupportStrike_Arty_Mortar_HE") > -1)	)
	{
			Pres.UITutorialBox( class'UIAlert_SupportStrikes'.default.strTitle_Ready_StrikeAvaliable, 
				class'UIAlert_SupportStrikes'.default.strDesc_Ready_StrikeAvaliable, "" );
	}

	return ELR_NoInterrupt;
}
*/