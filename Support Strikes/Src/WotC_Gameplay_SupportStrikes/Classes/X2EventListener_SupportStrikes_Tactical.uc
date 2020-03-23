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
	Template.AddCHEvent('OnTacticalBeginPlay', LoadOnDemandHeliDropIn, ELD_OnStateSubmitted, 99999);	//Same shit with highest priority
//	Template.AddCHEvent('PlayerTurnBegun', ShowSupportStrikeMessage, ELD_Immediate, -50);
	Template.RegisterInTactical = true;

	return Template;
}

// Modifies the Support Strike Manager based on what was taken in PreMission
static function EventListenerReturn OnTacticalBeginPlay(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory								History;
	local XComGameState										NewGameState;
	local XComGameState_HeadquartersXCom					XComHQ;
	local XComGameState_Unit								UnitState;
	local StateObjectReference								UnitRef;
//	local XComPresentationLayer								Pres;
//	local TDialogueBoxData									kData;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;
	local name												UnlockName;
	local int												Index;

	if (GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
//	Pres = `PRES;

	// Add streaming maps to the game
	AddStreamingCinematicMaps();

	// TQL/Skirmish/Ladder/Challenge Mode Does not have the manager installed
	if ( class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true) )
		return ELR_NoInterrupt;

	SupportStrikeMgr = XComGameState_SupportStrikeManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	// Nothing happens if there's no Support Strike Manager
	if (SupportStrikeMgr == none)
		return ELR_NoInterrupt;

	// Create a new gamestate since something will be modified
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("X2EventListener_SupportStrikes.OnTacticalBeginPlay");

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
//		kData.eType     = eDialog_Alert;
//		kData.strTitle  = class'UIAlert_SupportStrikes'.default.strTitle_Error_StrikeNotAvaliable;
//		kData.strText   = class'UIAlert_SupportStrikes'.default.strDesc_Reason_MissionSiteInvalid;
//		kData.strAccept = Pres.m_strOK;
//
//		Pres.UIRaiseDialog( kData );	
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
		SupportStrikeMgr.bValid = true;

//		Pres.UITutorialBox( class'UIAlert_SupportStrikes'.default.strTitle_Ready_StrikeAvaliable, 
//		class'UIAlert_SupportStrikes'.default.strDesc_Ready_StrikeAvaliable, "" );
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

	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Count: Disallowed Biomes: "$ class'X2Condition_MapCheck'.default.DisallowedBiomes.Length $", Disallowed Plots: "$ class'X2Condition_MapCheck'.default.DisallowedPlots.Length $", Disallowed Parcels: "$ class'X2Condition_MapCheck'.default.DisallowedParcels.Length ,class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(,true),'WotC_Gameplay_SupportStrikes');
	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Biome: " $ BattleData.MapData.Biome,class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(,true),'WotC_Gameplay_SupportStrikes');
	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Plot Type: " $ PlotType ,class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(,true),'WotC_Gameplay_SupportStrikes');

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

	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Condition Passed",class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(,true),'WotC_Gameplay_SupportStrikes');
	return false;
}

// Adds additional maps to the game manually
// TODO
static function AddStreamingCinematicMaps()
{
	local string strCineMap;

	foreach class'X2DownloadableContentInfo_WotC_SupportStrikes'.default.CinematicMaps(strCineMap)
		`MAPS.AddStreamingMap(strCineMap, , , false).bForceNoDupe = true;
}

//
// TODO: Fix this executing too early and executing multiple times in a mission (before the briefing is done)
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

static function EventListenerReturn LoadOnDemandHeliDropIn(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory								History;
	local XComGameState										NewGameState;
	local XComGameState_HeadquartersXCom					XComHQ;
	local XComGameState_Unit								UnitState;
	local StateObjectReference								UnitRef;
	local array<XComGameState_Item>							AllItems;
	local XComGameState_Item								Item;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;
	local bool												ItemFound;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// TQL/Skirmish/Ladder/Challenge Mode Does not have the manager installed
	// TODO: We'll need to evaluate every unit and see if a certain item was taken
	if ( class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true) )
	{
		foreach XComHQ.Squad(UnitRef)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (UnitState != none)
			{
				AllItems = UnitState.GetAllInventoryItems(GameState, true);
				foreach AllItems(Item)
				{
					//We found the unit who has this item, break off
					if  ( Item.GetMyTemplate().DataName == 'Support_Air_Defensive_HeliDropIn_T1') 
					{
						ItemFound = true;
						break;
					}
				}

				if (ItemFound)
					break;
			}
		}

		`LOG("[LoadOnDemandHeliDropIn()] Found UnitState: " $ UnitState.GetFullName() $ " with Object ID: " $ UnitState.ObjectID ,,'WotC_Gameplay_SupportStrikes');

		// Create a new gamestate since something will be modified
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("OnTacticalBeginPlay.LoadOnDemandHeliDropIn()");

		SpawnUnitsPreLoadSequence(UnitState, NewGameState);
	}
	else
	{
		// We're in a campaign and we do have a Support Strike Manager
		SupportStrikeMgr = XComGameState_SupportStrikeManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

		// Nothing happens if there's no Support Strike Manager
		if (SupportStrikeMgr == none)
			return ELR_NoInterrupt;

		// Create a new gamestate since something will be modified
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("OnTacticalBeginPlay.LoadOnDemandHeliDropIn()");

		//Find the first unit in the squad
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[0].ObjectID));

		SpawnUnitsPreLoadSequence(UnitState, NewGameState);
	}

	// If something happened, submit gamestate
	// Otherwise, clean up the gamestate
	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`LOG("[LoadOnDemandHeliDropIn()] Submitted changes to history." ,,'WotC_Gameplay_SupportStrikes');
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

static function SpawnUnitsPreLoadSequence(XComGameState_Unit UnitStateSelf, XComGameState NewGameState)
{
	local XComGameState_Unit				SpawnedUnit;
	local XComGameStateHistory				History;
	local StateObjectReference				NewUnitRef;
	local Vector							SpawnLocation;
	local int								i, Idx;
	local XComDropTrooperData				ChosenData;
	local XComGameState_AIGroup				NewGroupState;
	local XComGameState_BattleData			BattleData;
	local SpawnCharacterData				PilotCharTemplate;

	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// Choose a XComDropTrooperData struct
	if (class'X2Effect_SpawnSquad'.default.arrSpawnUnitData.Length == 0)
	{
		`LOG("[TriggerSpawnEvent()] ERROR, No DataSet exists!",, 'WotC_Gameplay_SupportStrikes');
		return;
	}
	ChosenData = class'X2Effect_SpawnSquad'.static.PickBestDataSet(BattleData.GetForceLevel());

	//	spawn under the map, another function (preferably the effect itself) will relocate the units to the proper positions
	SpawnLocation = vect(-10000,-10000,-10000);

	// Create a brand new singleton AI Group exclusively for the Trooper Swarm
	// SpawnManager will stuff the units in here automatically once we have the ObjectID
	// Once we're done, we'll use this for our Event Listener and send orders to and fro
	NewGroupState = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));
	NewGroupState.EncounterID	= class'X2Effect_SpawnSquad'.default.EncounterID;
	NewGroupState.TeamName		= eTeam_XCom;

	`LOG("[SpawnUnitsPreLoadSequence()] Created AIGroup GameState with Object ID " $ NewGroupState.ObjectID, , 'WotC_Gameplay_SupportStrikes');
	`LOG("[SpawnUnitsPreLoadSequence()] ChosenData.MaxUnitsToSpawn: " $ ChosenData.MaxUnitsToSpawn,, 'WotC_Gameplay_SupportStrikes');

	//	Spawn Max Soldiers
	for (i = 0; i < ChosenData.MaxUnitsToSpawn; i++)
	{
		if (ChosenData.bSequential)	// Be sure not to go beyond index, use modulo to return back to 0
			SpawnedUnit = class'X2Effect_SpawnSquad'.static.AddXComFriendliesToTactical( ChosenData.CharacterTemplate[i % ChosenData.CharacterTemplate.Length], 
			NewGameState, SpawnLocation, NewGroupState.ObjectID);
		else	// Randomly roll each iteration
			SpawnedUnit = class'X2Effect_SpawnSquad'.static.AddXComFriendliesToTactical( ChosenData.CharacterTemplate[`SYNC_RAND_STATIC(ChosenData.CharacterTemplate.Length)], 
			NewGameState, SpawnLocation, NewGroupState.ObjectID);

		NewUnitRef = SpawnedUnit.GetReference();

		//	we use a Unit Value on the target of the persistent effect to store the Reference of the soldier we just spawned
		//	the ability that applied this persistent effect will use this Reference in its Build Visulization function to propely visualize the soldier's spawning
		UnitStateSelf.SetUnitFloatValue(name(class'X2Effect_SpawnSquad'.default.SpawnedUnitValueName $ i), NewUnitRef.ObjectID, eCleanup_Never);

		//	Create the actors on demand
		CreateVisualizersForActors(NewUnitRef, NewGameState);

		//Disable Action Points and stick him in stasis so other units can ignore them
		SpawnedUnit.ActionPoints.Length = 0;
		SpawnedUnit.ReserveActionPoints.Length = 0;
		SpawnedUnit.SetUnitFloatValue('eStat_SightRadius', SpawnedUnit.GetVisibilityRadius(), eCleanup_Never);
		SpawnedUnit.SetBaseMaxStat(eStat_SightRadius, 0);

		// This is here so that CreateVisualizersForActors doesn't destroy the actor when calling SyncVisualizer()
		//  Prevent enemies from spotting units by accident and revealing FOW
		SpawnedUnit.RemoveStateFromPlay();
	}

	//Start from this index for bottom loop
	i = ChosenData.MaxUnitsToSpawn;

	// Find Spawndata for pilots
	// Pilots by default are cosmetic, so nothing else needs to be done for them after creating the visualizer
	Idx = class'X2Effect_SpawnSquad'.default.arrSpawnUnitData.Find('bIsPilot', true);
	if (Idx != INDEX_NONE)
	{
		foreach class'X2Effect_SpawnSquad'.default.arrSpawnUnitData[Idx].CharacterTemplate(PilotCharTemplate)
		{
			SpawnedUnit = class'X2Effect_SpawnSquad'.static.AddXComFriendliesToTactical ( PilotCharTemplate, 
			NewGameState, SpawnLocation,NewGroupState.ObjectID, true);

			NewUnitRef = SpawnedUnit.GetReference();

			//	we use a Unit Value on the target of the persistent effect to store the Reference of the soldier we just spawned
			//	the ability that applied this persistent effect will use this Reference in its Build Visulization function to propely visualize the soldier's spawning
			UnitStateSelf.SetUnitFloatValue(name(class'X2Effect_SpawnSquad'.default.SpawnedUnitValueName $ i), NewUnitRef.ObjectID, eCleanup_Never);
			i++;

			//	Create the actors on demand
			CreateVisualizersForActors(NewUnitRef, NewGameState);
		}
	}

	//Update FOW
	`XWORLD.ForceUpdateAllFOWViewers( );
}

//
// We need to create the visualization actor ahead of time, before the game has even started
//
static function CreateVisualizersForActors(StateObjectReference NewUnitRef, XComGameState NewGameState)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));

	if( Unit.GetVisualizer() == none )
	{
		Unit.FindOrCreateVisualizer();
		Unit.SyncVisualizer();

		//Stay hidden until the Matinee plays
		XGUnit(Unit.GetVisualizer()).m_bForceHidden = true;
	}
}