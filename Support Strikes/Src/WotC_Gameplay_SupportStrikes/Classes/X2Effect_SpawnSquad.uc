//
// FILE:	X2Effect_IRI_SpawnSoldier
// AUTHOR:	Iridar, edits by E3245
// DESC:	Re-purposed SpawnSoldier for Calling in Reinforcements
//			Removes smoke effect on soldiers contextually instead of normally just checking if the soldier is on a tile.
//			This means that once the soldier leaves the smoke clouds, the effect is removed, down to the non-smoked tile.
//

class X2Effect_SpawnSquad extends X2Effect_Persistent config(GameData_SupportStrikes);

//	this is the name of the Unit Value that will be used to store the Object Reference of spawned units
//	so it can be passed along to the BuildVisualization function of the ability that applied this persistent effect
var privatewrite name					SpawnedUnitValueName;

var privatewrite name					EncounterID;

var privatewrite name					IsACosmeticUnit;

var() int								MaxSoldiers;
var() int								MaxPilots;

var() bool								bSpawnCosmeticSoldiers;

var config int							SpawnedUnit_StandardAP;
var config int							SpawnedUnit_MovementOnlyAP;

var privatewrite array<TTile>			UnusedLocations; // At this point of the spawning, the unit doesn't exist yet. We need this property to store which tiles were already picked

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnitState;

	TargetUnitState = XComGameState_Unit(kNewTargetState);

	if (TargetUnitState == none) 
	{
		`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Spawn Soldier effect was magically applied to a non-existent unit!", , 'WotC_Gameplay_SupportStrikes');
	}

	`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Begin Spawn Event", , 'WotC_Gameplay_SupportStrikes');

	TriggerSpawnEvent(ApplyEffectParameters, TargetUnitState, NewGameState);

	`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Event Completed", , 'WotC_Gameplay_SupportStrikes');
}

function TriggerSpawnEvent(const out EffectAppliedData ApplyEffectParameters, XComGameState_Unit EffectTargetUnit, XComGameState NewGameState)
{
	local XComGameState_Unit					TargetUnitState, SpawnedUnit;
	local XComGameStateHistory					History;
	local int									i, Idx;
	local XComGameState_AIGroup					NewGroupState;
	local XComGameState_SupportStrikeManager	SupportStrikeMgr;
	local XComGameState_SupportStrike_Tactical	StrikeTactical;
	local XComWorldData							World;
	local vector								Veck;
	local TTile									kTile;
	local array<TTile>							FinalTiles;

	Idx = 0;

	History = `XCOMHISTORY;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnitState == none) 
	{
		`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Failed to get the history for Unit State of the Spawn Soldier effect's target!", , 'WotC_Gameplay_SupportStrikes');
		`Redscreen("Failed to get the history for Unit State of the Spawn Soldier effect's target");
	}

	// Get the ability state object from the AEP so we can access the Stage 2's Multi Target style
//	AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));	
//	AbilityTemplate = AbilityStateObject.GetMyTemplate();
//
//	if( AbilityTemplate.AbilityMultiTargetStyle != none )
//	{
//		AbilityTemplate.AbilityMultiTargetStyle.GetValidTilesForLocation(AbilityStateObject, ApplyEffectParameters.AbilityInputContext.TargetLocations[0], UnusedLocations);
//		`LOG("[" $ GetFuncName() $ "] Generated " $ UnusedLocations.Length $ " possible locations from the center: " $ ApplyEffectParameters.AbilityInputContext.TargetLocations[0], , 'WotC_Gameplay_SupportStrikes');
//	}


	World = `XWORLD;
	UnusedLocations = ApplyEffectParameters.AbilityResultContext.RelevantEffectTiles;

	`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Generated " $ UnusedLocations.Length $ " possible locations from the center: " $ ApplyEffectParameters.AbilityInputContext.TargetLocations[0], , 'WotC_Gameplay_SupportStrikes');

	//filter through all tiles and prune tiles that are not on the floor
	foreach UnusedLocations(kTile)
	{
		if ( World.GetFloorPositionForTile(kTile, Veck) )
			FinalTiles.AddItem(kTile);
	}

	// Copy the array back into our tiles
	UnusedLocations = FinalTiles;

	`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Pruned non-floor and invalid tiles and are left with " $ UnusedLocations.Length $ " possible locations from the center: " $ ApplyEffectParameters.AbilityInputContext.TargetLocations[0], , 'WotC_Gameplay_SupportStrikes');

	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));
	StrikeTactical = XComGameState_SupportStrike_Tactical(History.GetGameStateForObjectID(SupportStrikeMgr.TacticalGameState.ObjectID));

	// Create a brand new singleton AI Group exclusively for the Trooper Swarm
	// SpawnManager will stuff the units in here automatically once we have the ObjectID
	// Once we're done, we'll use this for our Event Listener and send orders to and fro
	NewGroupState = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));
	NewGroupState.EncounterID	= EncounterID;
	NewGroupState.TeamName		= eTeam_XCom;

	`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Created AIGroup GameState with Object ID " $ NewGroupState.ObjectID, , 'WotC_Gameplay_SupportStrikes');

	`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Querying Object: " $ StrikeTactical.XComResistanceRNFIDs.Length $ " Soldiers, " $ StrikeTactical.CosmeticResistanceRNFIDs.Length $ " Copies, and " $ StrikeTactical.Pilots.Length $ " Pilots." ,, 'WotC_Gameplay_SupportStrikes');

	//	Spawn Max Soldiers
	for (i = 0; i < MaxSoldiers; i++)
	{
		`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Grabbing ObjectID: " $ StrikeTactical.XComResistanceRNFIDs[i].ObjectID ,, 'WotC_Gameplay_SupportStrikes');
		SpawnedUnit = AddXComFriendliesToTactical( StrikeTactical.XComResistanceRNFIDs[i], NewGameState, GetSpawnLocation(ApplyEffectParameters, NewGameState), NewGroupState);
		//	we use a Unit Value on the target of the persistent effect to store the Reference of the soldier we just spawned
		//	the ability that applied this persistent effect will use this Reference in its Build Visulization function to propely visualize the soldier's spawning
		EffectTargetUnit.SetUnitFloatValue(name(default.SpawnedUnitValueName $ Idx), SpawnedUnit.ObjectID, eCleanup_BeginTurn);
		//	Do some final hair licking for each newly spawned soldier
		OnSpawnComplete(ApplyEffectParameters, StrikeTactical.XComResistanceRNFIDs[i], NewGameState);

		`XEVENTMGR .TriggerEvent('UnitSpawned', SpawnedUnit, SpawnedUnit);
		
		Idx++;
	}

	//	Spawn Max Soldiers
	if (bSpawnCosmeticSoldiers)
	{
		for (i = 0; i < MaxSoldiers; i++)
		{
			// Spawn in the cosmetic units too
			`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Grabbing ObjectID: " $ StrikeTactical.CosmeticResistanceRNFIDs[i].ObjectID ,, 'WotC_Gameplay_SupportStrikes');
			SpawnedUnit = AddXComFriendliesToTactical( StrikeTactical.CosmeticResistanceRNFIDs[i], NewGameState, vect(0,0,0), NewGroupState, true);
			EffectTargetUnit.SetUnitFloatValue(name(default.SpawnedUnitValueName $ Idx), SpawnedUnit.ObjectID, eCleanup_BeginTurn);

			// Commented out since the unit's visualizer will be destroyed after the matinee plays
			//OnSpawnComplete(ApplyEffectParameters, StrikeTactical.CosmeticResistanceRNFIDs[i], NewGameState);
			Idx++;
		}
	}

	for (i = 0; i < MaxPilots; i++)
	{
		// Spawn in pilots
		`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Grabbing ObjectID: " $ StrikeTactical.Pilots[i].ObjectID ,class'X2Helpers_MiscFunctions'.static.Log(,true), 'WotC_Gameplay_SupportStrikes');
		SpawnedUnit = AddXComFriendliesToTactical ( StrikeTactical.Pilots[i], NewGameState, vect(0,0,0), NewGroupState, true);
		EffectTargetUnit.SetUnitFloatValue(name(default.SpawnedUnitValueName $ Idx), SpawnedUnit.ObjectID, eCleanup_BeginTurn);

		// Commented out since the unit's visualizer will be destroyed after the matinee plays
		//OnSpawnComplete(ApplyEffectParameters, StrikeTactical.Pilots[i], NewGameState);
		Idx++;
	}

	`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Index count: " $ Idx ,, 'WotC_Gameplay_SupportStrikes');
}

function vector GetSpawnLocation(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local int				Idx;
	local XComWorldData		World;
	local TTile				ChosenTile;
	local vector			Destination;

	Idx = `SYNC_RAND(0, UnusedLocations.Length);
	World = `XWORLD;

	ChosenTile = UnusedLocations[Idx];

	//Pop it off the stack
	UnusedLocations.Remove(Idx, 1);
	
	// Do a second check to make sure we get a tile that's not blocked
	// May overlap since the unit hasn't existed yet
	//ChosenTile = class'Helpers'.static.GetClosestValidTile(ChosenTile);

	Destination = World.GetPositionFromTileCoordinates(ChosenTile);

	`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Picked Vector: " $ Destination, , 'WotC_Gameplay_SupportStrikes');

	return Destination;
}

// Spawn a random unit into tactical mission
public static function XComGameState_Unit AddXComFriendliesToTactical(StateObjectReference UnitRef, XComGameState NewGameState, Vector SpawnLocation, XComGameState_AIGroup AIGroup, optional bool bIsCineActor = false)
{
	local XComGameStateHistory				History;
	local XComGameState_Unit				SpawnedUnit;
	local XComGameState_Player				PlayerState;
	local StateObjectReference				ItemReference;
	local XComGameState_Item				ItemState;
	local XComGameState_BattleData			BattleData;
	local XComGameState_AIGroup				PreviousGroupState;
	local X2EventManager					EventManager;

	History = `XCOMHISTORY;

	// Bad ObjectID test
	if (UnitRef.ObjectID == 0)
	{
		`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] ERROR, Invalid ObjectID was sent in!",, 'WotC_Gameplay_SupportStrikes');
		return none;
	}
	
	//Create a new object with the same ID
	SpawnedUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitRef.ObjectID));

	SpawnedUnit.BeginTacticalPlay(NewGameState);	// this needs to be called explicitly since we're adding an existing state directly into tactical
	SpawnedUnit.bTriggerRevealAI = false;			// Skip over since we've just spawned in

	if (!SpawnedUnit.bMissionProvided)
		SpawnedUnit.bMissionProvided = true;

	// Move the unit to the spawn location according to the AEP object
	SpawnedUnit.SetVisibilityLocationFromVector(SpawnLocation);

	// assign the new unit to the human team
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if(PlayerState.GetTeam() == eTeam_XCom)
		{
			SpawnedUnit.SetControllingPlayer(PlayerState.GetReference());
			break;
		}
	}

	// add item states. This needs to be done so that the visualizer sync picks up the IDs and creates their visualizers -LEB
	foreach SpawnedUnit.InventoryItems(ItemReference)
	{
		ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemReference.ObjectID));
		ItemState.BeginTacticalPlay(NewGameState);   // this needs to be called explicitly since we're adding an existing state directly into tactical
		NewGameState.AddStateObject(ItemState);

		// add any cosmetic items that might exists
		ItemState.CreateCosmeticItemUnit(NewGameState);
	}

	if (!bIsCineActor || !SpawnedUnit.GetMyTemplate().bIsCosmetic)
	{
		// Testing for now, remove the group state when handing the group to the AI
		AIGroup = GetPlayerGroup();
		if (AIGroup != none )
		{
			PreviousGroupState = SpawnedUnit.GetGroupMembership(NewGameState);

			if( PreviousGroupState != none ) PreviousGroupState.RemoveUnitFromGroup(SpawnedUnit.ObjectID, NewGameState);

			AIGroup = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', AIGroup.ObjectID));
			AIGroup.AddUnitToGroup(SpawnedUnit.ObjectID, NewGameState);
		}
		else
		`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] ERROR, No AIGroup that belongs to the player was found", , 'WotC_Gameplay_SupportStrikes');

		//Add the new unit to the AI group
		//AIGroup.AddUnitToGroup(SpawnedUnit.ObjectID, NewGameState);
		//
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		if( BattleData.UnitActionInitiativeRef.ObjectID == AIGroup.ObjectID )
		{
			SpawnedUnit.SetupActionsForBeginTurn();
		}
		else
		{
			if( BattleData.PlayerTurnOrder.Find('ObjectID', AIGroup.ObjectID) == INDEX_NONE )
			{
				`TACTICALRULES.AddGroupToInitiativeOrder(AIGroup, NewGameState);
			}
		}
	}

	// Trigger that this unit has been spawned before we submit the entry
	EventManager = `XEVENTMGR;
	EventManager.TriggerEvent('UnitSpawned', SpawnedUnit, SpawnedUnit);

	// submit it -LEB
	NewGameState.AddStateObject(SpawnedUnit);
	XComGameStateContext_TacticalGameRule(NewGameState.GetContext()).UnitRef = SpawnedUnit.GetReference();

	// add abilities
	// Must happen after unit is submitted, or it gets confused about when the unit is in play or not 
	`TACTICALRULES.InitializeUnitAbilities(NewGameState, SpawnedUnit);


	`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] Spawned Unit: " $ SpawnedUnit.GetFullName() $ " Of Template: " $ SpawnedUnit.GetMyTemplate().DataName $ " with ObjectID " $ SpawnedUnit.ObjectID, , 'WotC_Gameplay_SupportStrikes');

	return SpawnedUnit;
}

static function XComGameState_AIGroup GetPlayerGroup()
{
	local XComGameState_AIGroup AIGroupState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AIGroup', AIGroupState)
	{
		if (AIGroupState.TeamName == eTeam_XCom)
		{
			return AIGroupState;
		}
	}

	return none;
}

// Helper functions to quickly get teams for inheriting classes -LEB
protected function ETeam GetTargetUnitsTeam(const out EffectAppliedData ApplyEffectParameters, optional bool UseOriginalTeam=false)
{
	local XComGameState_Unit TargetUnit;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// Defaults to the team of the unit that this effect is on
	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	`assert(TargetUnit != none);

	if( UseOriginalTeam )
	{
		return GetUnitsOriginalTeam(TargetUnit);
	}

	return TargetUnit.GetTeam();
}


protected function ETeam GetSourceUnitsTeam(const out EffectAppliedData ApplyEffectParameters, optional bool UseOriginalTeam=false)
{
	local XComGameState_Unit SourceUnit;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// Defaults to the team of the unit that this effect is on -LEB
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	`assert(SourceUnit != none);

	if( UseOriginalTeam )
	{
		return GetUnitsOriginalTeam(SourceUnit);
	}

	return SourceUnit.GetTeam();
}

// Things like mind control may change a unit's team. This grabs the team the unit was originally on. -LEB
protected function ETeam GetUnitsOriginalTeam(const out XComGameState_Unit UnitGameState)
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// find the original game state for this unit
	UnitState = XComGameState_Unit(History.GetOriginalGameStateRevision(UnitGameState.ObjectID));
	`assert(UnitState != none);

	return UnitState.GetTeam();
}

//	visualization function that will make spawned units play an animation when entering the world
//	it is called from withing Build Vis function of the ability that applies this effect
function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationActionMetadata SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationActionMetadata EffectTargetUnitTrack)
{

	if( SpawnedUnit.GetVisualizer() == none )
	{
		SpawnedUnit.FindOrCreateVisualizer();
		SpawnedUnit.SyncVisualizer();

		//Make sure they're hidden until ShowSpawnedUnit makes them visible (SyncVisualizer unhides them)
		XGUnit(SpawnedUnit.GetVisualizer()).m_bForceHidden = true;
		`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] " $ SpawnedUnit.GetFullName() $ "'s visualizer initialized" ,, 'WotC_Strategy_SupportStrikes');
	}
	else
		`LOG("[X2Effect_SpawnSquad::" $ GetFuncName() $ "] WARNING, " $ SpawnedUnit.GetFullName() $ " already has a visualizer initialized!" ,, 'WotC_Strategy_SupportStrikes');
}

// Get the team that this unit should be added to -LEB
function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return eTeam_XCom;
}

// Any clean up or final updates that need to occur after the unit is spawned -LEB
function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState)
{
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local int i;

	Unit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	History = `XCOMHISTORY;

	//add actionpoints
//	for(i=0;i<class'X2Helper_SpawnUnit'.default.SpawnedUnit_StandardAP;i++) Unit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
//	for(i=0;i<class'X2Helper_SpawnUnit'.default.SpawnedUnit_MovementOnlyAP;i++) Unit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);

	for(i=0;i<2;i++) 
		Unit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	for(i=0;i<2;i++) 
		Unit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	//	add the newly spawned unit to the first empty squad slot so they appear walking out of Skyranger after the mission

	XComHQ.Squad.AddItem( Unit.GetReference() );
	XComHQ.AllSquads[0].SquadMembers.AddItem( Unit.GetReference() );
}

defaultproperties
{
	SpawnedUnitValueName="SpawnedSquadUnitValue"
	IsACosmeticUnit = "IsACosmeticUnit"

	EffectName="SpawnSquadEffect"
	DuplicateResponse=eDupe_Ignore

	EncounterID = "XComTrooperSwarm";

	MaxSoldiers = 2;
	MaxPilots = 1;
}