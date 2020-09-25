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
//	Template.AddCHEvent('OnTacticalBeginPlay', LoadOnDemandHeliDropIn, ELD_OnStateSubmitted, 99999);	//Same shit with highest priority
	Template.AddCHEvent('KillMail', RemoveFromStrikeManager, ELD_Immediate, 50);
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
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;
	local XComGameState_SupportStrike_Tactical				StrikeTactical;
	local name												UnlockName;

	if (GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
//	Pres = `PRES;

	// TQL/Skirmish/Ladder/Challenge Mode Does not have the manager installed
	if ( class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true) )
		return ELR_NoInterrupt;

	SupportStrikeMgr = XComGameState_SupportStrikeManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	// Nothing happens if there's no Support Strike Manager
	if (SupportStrikeMgr == none)
		return ELR_NoInterrupt;

	// If there is no strikes bought or if the "Not enough resources" flag is raised, exit listener
	if (SupportStrikeMgr.PurchasedSupportStrikes.Length == 0 || SupportStrikeMgr.bInvalid_NoResources)
	{
		`LOG("[OnTacticalBeginPlay()] Player has no Strikes." ,,'WotC_Gameplay_SupportStrikes');
		return ELR_NoInterrupt;
	}

	// Create a new gamestate since something will be modified
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("X2EventListener_SupportStrikes.OnTacticalBeginPlay");

	SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

	//
	//		* Check Environment
	//		* Add popup message if strikes are not supported here
	//
	if ( DoesGeneratedMissionHaveInvalidMap(History) )
	{
		`LOG("[OnTacticalBeginPlay()] No Z-level Clearance in map." ,,'WotC_Gameplay_SupportStrikes');
		SupportStrikeMgr.bInvalid_HeightClearance = true;
	}
	// If the flag is not raised, then there's support strikes to add
	else
	{
		//Add our cinematic map to the game
		StrikeTactical = XComGameState_SupportStrike_Tactical(History.GetGameStateForObjectID(SupportStrikeMgr.TacticalGameState.ObjectID));

		// Add any cinematic umaps to the game
		if (StrikeTactical != none)
			AddStreamingCinematicMaps(StrikeTactical);

		// Check all units in the squad and add the appropriate items (this includes sitrep units)
		foreach XComHQ.Squad(UnitRef)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (UnitState != none)
			{
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				foreach SupportStrikeMgr.CurrentMissionSupportStrikes(UnlockName)
				{
					class'X2Helpers_MiscFunctions'.static.GiveItem(UnlockName, UnitState, NewGameState);
					`LOG("[OnTacticalBeginPlay()] " $ UnitState.GetFullName() $ " has been given " $ UnlockName,,'WotC_Gameplay_SupportStrikes');
				}
			}
		}

		// Report to the player that the support team is ready for instructions
		// This will eventually be replaced with a Narrative moment
		SupportStrikeMgr.bValid = true;
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

	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Count: Disallowed Biomes: "$ class'X2Condition_MapCheck'.default.DisallowedBiomes.Length $", Disallowed Plots: "$ class'X2Condition_MapCheck'.default.DisallowedPlots.Length $", Disallowed Parcels: "$ class'X2Condition_MapCheck'.default.DisallowedParcels.Length ,class'X2Helpers_MiscFunctions'.static.Log(,true),'WotC_Gameplay_SupportStrikes');
	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Biome: " $ BattleData.MapData.Biome,class'X2Helpers_MiscFunctions'.static.Log(,true),'WotC_Gameplay_SupportStrikes');
	`LOG("[X2EventListener_SupportStrikes.DoesGeneratedMissionHaveInvalidMap()] Plot Type: " $ PlotType ,class'X2Helpers_MiscFunctions'.static.Log(,true),'WotC_Gameplay_SupportStrikes');

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

//
// When a unit spawned from the heli dies, remove the unit from the support strike tactical gamestate. We don't care about the EventSource (Killer) in this instance.
//
static function EventListenerReturn RemoveFromStrikeManager(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory								History;
	local XComGameState										NewGameState;
	local XComGameState_Unit								KilledUnit;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;
	local XComGameState_SupportStrike_Tactical				StrikeTactical;
	local UnitValue											Value;

	KilledUnit = XComGameState_Unit(EventData);

	if (KilledUnit == none)
		return ELR_NoInterrupt;

	// TQL/Skirmish/Ladder/Challenge Mode Does not have the manager installed
	if ( class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true) )
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;

	//Get our support strike tactical XCGS ready
	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));
	StrikeTactical = XComGameState_SupportStrike_Tactical(History.GetGameStateForObjectID(SupportStrikeMgr.TacticalGameState.ObjectID));

	if (StrikeTactical == none)
		return ELR_NoInterrupt;

	if (KilledUnit.TacticalTag != StrikeTactical.TacticalTag)
		return ELR_NoInterrupt;

	// Create a new gamestate since something will be modified
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SupportStrike_Tactical.KillMail()");

	StrikeTactical = XComGameState_SupportStrike_Tactical(NewGameState.ModifyStateObject(class'XComGameState_SupportStrike_Tactical', StrikeTactical.ObjectID));

	// Retrieve the unit value from the unit
	KilledUnit.GetUnitValue(StrikeTactical.UVIndexName, Value);

	//Remove the element from the array
	StrikeTactical.XComResistanceRNFIDs.Remove(int(Value.fValue), 1);
	StrikeTactical.CosmeticResistanceRNFIDs.Remove(int(Value.fValue), 1);



	// If something happened, submit gamestate
	// Otherwise, clean up the gamestate
	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`LOG("[" $ GetFuncName() $ "] Submitted changes to history." ,,'WotC_Gameplay_SupportStrikes');
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	return ELR_NoInterrupt;

}

static function AddStreamingCinematicMaps(XComGameState_SupportStrike_Tactical StrikeTactical)
{
	local string strCineMap;

	foreach StrikeTactical.default.CinematicMaps(strCineMap)
		`MAPS.AddStreamingMap(strCineMap, , , false).bForceNoDupe = true;
}
/*
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
*/
/*
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
	*/
//
// We need to create the visualization actor ahead of time, before the game has even started
//
/*
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
*/