//
// FILE:	X2Effect_IRI_SpawnSoldier
// AUTHOR:	Iridar, edits by E3245
// DESC:	Re-purposed SpawnSoldier for Calling in Reinforcements
//			Removes smoke effect on soldiers contextually instead of normally just checking if the soldier is on a tile.
//			This means that once the soldier leaves the smoke clouds, the effect is removed, down to the non-smoked tile.
//

class X2Effect_SpawnSquad extends X2Effect_Persistent config(GameData_SupportStrikes);

struct SpawnCharacterData
{
	var name TemplateName;
	var string CharacterPoolName;
	var name WPNCategory;		// GiveItem executes if true for possible primary and secondary weapons
	structdefaultproperties
	{
		CharacterPoolName = "";
	}
};

struct XComDropTrooperData
{
	var bool bSequential;			// If false, it's randomly picked
	var bool bIsPilot;				// Special case for Matinee
	var array<SpawnCharacterData> CharacterTemplate;
	var int MinForceLevel;
	var int MaxForceLevel;
	var int AlertLevel;
	var int MaxUnitsToSpawn;

	structdefaultproperties
	{
		AlertLevel = 0;
		MinForceLevel = 0;
		MaxForceLevel = 0;
		MaxUnitsToSpawn = 0;
	}
};


struct WeaponDataIntermediary 
{
	var name PriWeaponTemplate;
	var name SecWeaponTemplate;
	structdefaultproperties
	{
		PriWeaponTemplate = none;
		SecWeaponTemplate = none;
	}
};

struct RandomWeaponData
{
	var name Category;
	var array<WeaponDataIntermediary> arrWeapons;
};


var config array<XComDropTrooperData>	arrSpawnUnitData;
var config array<RandomWeaponData>		arrRandomWeapons;
var config int							SpawnedUnit_StandardAP;
var config int							SpawnedUnit_MovementOnlyAP;

//	this is the name of the Unit Value that will be used to store the Object Reference of spawned units
//	so it can be passed along to the BuildVisualization function of the ability that applied this persistent effect
var privatewrite name SpawnedUnitValueName;

var privatewrite name EncounterID;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnitState;

	TargetUnitState = XComGameState_Unit(kNewTargetState);

	if (TargetUnitState == none) 
	{
		`LOG("[OnEffectAdded()] Spawn Soldier effect was magically applied to a non-existent unit!", , 'WotC_Gameplay_SupportStrikes');
	}

	`LOG("[OnEffectAdded()] Begin Spawn Event", , 'WotC_Gameplay_SupportStrikes');

	// We've already done this
//	TriggerSpawnEvent(ApplyEffectParameters, TargetUnitState, NewGameState);

	`LOG("[OnEffectAdded()] Event Completed", , 'WotC_Gameplay_SupportStrikes');
}

/*
function TriggerSpawnEvent(const out EffectAppliedData ApplyEffectParameters, XComGameState_Unit EffectTargetUnit, XComGameState NewGameState)
{
	local XComGameState_Unit				TargetUnitState, SpawnedUnit;
	local XComGameStateHistory				History;
	local StateObjectReference				NewUnitRef;
	local Vector							SpawnLocation;
	local int								i, Idx;
	local XComDropTrooperData				ChosenData;
	local XComGameState_AIGroup				NewGroupState;
	local XComGameState_BattleData			BattleData;
	local SpawnCharacterData				PilotCharTemplate;

	History = `XCOMHISTORY;
	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnitState == none) 
	{
		`LOG("[OnEffectAdded()] Failed to get the history for Unit State of the Spawn Soldier effect's target!", , 'WotC_Gameplay_SupportStrikes');
		`Redscreen("Failed to get the history for Unit State of the Spawn Soldier effect's target");
	}

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// Choose a XComDropTrooperData struct
	if (default.arrSpawnUnitData.Length == 0)
	{
		`LOG("[TriggerSpawnEvent()] ERROR, No DataSet exists!",, 'WotC_Gameplay_SupportStrikes');
		return;
	}
	ChosenData = PickBestDataSet(BattleData.GetForceLevel());

	//	get a the spawn location
	SpawnLocation = GetSpawnLocation(ApplyEffectParameters, NewGameState);

	// Create a brand new singleton AI Group exclusively for the Trooper Swarm
	// SpawnManager will stuff the units in here automatically once we have the ObjectID
	// Once we're done, we'll use this for our Event Listener and send orders to and fro
	NewGroupState = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));
	NewGroupState.EncounterID	= EncounterID;
	NewGroupState.TeamName		= eTeam_XCom;

	`LOG("[TriggerSpawnEvent()] Created AIGroup GameState with Object ID " $ NewGroupState.ObjectID, , 'WotC_Gameplay_SupportStrikes');
	`LOG("[TriggerSpawnEvent()] ChosenData.MaxUnitsToSpawn: " $ ChosenData.MaxUnitsToSpawn,, 'WotC_Gameplay_SupportStrikes');

	//	Spawn Max Soldiers
	for (i = 0; i < ChosenData.MaxUnitsToSpawn; i++)
	{
		if (ChosenData.bSequential)	// Be sure not to go beyond index, use modulo to return back to 0
			SpawnedUnit = AddXComFriendliesToTactical( ChosenData.CharacterTemplate[i % ChosenData.CharacterTemplate.Length], NewGameState, SpawnLocation, NewGroupState.ObjectID);
		else	// Randomly roll each iteration
			SpawnedUnit = AddXComFriendliesToTactical( ChosenData.CharacterTemplate[`SYNC_RAND_STATIC(ChosenData.CharacterTemplate.Length)], NewGameState, SpawnLocation, NewGroupState.ObjectID);

		NewUnitRef = SpawnedUnit.GetReference();

		//	we use a Unit Value on the target of the persistent effect to store the Reference of the soldier we just spawned
		//	the ability that applied this persistent effect will use this Reference in its Build Visulization function to propely visualize the soldier's spawning
		EffectTargetUnit.SetUnitFloatValue(name(default.SpawnedUnitValueName $ i), NewUnitRef.ObjectID, eCleanup_BeginTurn);

		//	Do some final hair licking for each newly spawned soldier
		OnSpawnComplete(ApplyEffectParameters, NewUnitRef, NewGameState);
	}

	//Start from this index for bottom loop
	i = ChosenData.MaxUnitsToSpawn;

	// Find Spawndata for pilots
	Idx = default.arrSpawnUnitData.Find('bIsPilot', true);
	if (Idx != INDEX_NONE)
	{
		foreach default.arrSpawnUnitData[Idx].CharacterTemplate(PilotCharTemplate)
		{
			SpawnedUnit = AddXComFriendliesToTactical ( PilotCharTemplate, NewGameState, SpawnLocation, NewGroupState.ObjectID, true);

			NewUnitRef = SpawnedUnit.GetReference();

			//	we use a Unit Value on the target of the persistent effect to store the Reference of the soldier we just spawned
			//	the ability that applied this persistent effect will use this Reference in its Build Visulization function to propely visualize the soldier's spawning
			EffectTargetUnit.SetUnitFloatValue(name(default.SpawnedUnitValueName $ i), NewUnitRef.ObjectID, eCleanup_BeginTurn);
			i++;
			//	Do some final hair licking for each newly spawned soldier
			OnSpawnComplete(ApplyEffectParameters, NewUnitRef, NewGameState);
		}
	}
}
*/
function vector GetSpawnLocation(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{

	if(ApplyEffectParameters.AbilityInputContext.TargetLocations.Length == 0)
	{
		`LOG("Attempting to create X2Effect_SpawnDummyTarget without a target location!",, 'WotC_Gameplay_SupportStrikes');
		return vect(0,0,0);
	}

	return ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
}

// Not the best optimization ever in picking the closest Dataset between a range
public static function XComDropTrooperData PickBestDataSet(int ForceLevel)
{
	local int i;

	`LOG("[PickBestDataSet()] Current force level: " $ ForceLevel,, 'WotC_Gameplay_SupportStrikes');

	for (i = 0; i < default.arrSpawnUnitData.Length; i++)
	{
		//Skip over empty Character Template arrays
		if (default.arrSpawnUnitData[i].CharacterTemplate.Length == 0)
			continue;

		if ( (ForceLevel >= default.arrSpawnUnitData[i].MinForceLevel) &&
			 (ForceLevel <= default.arrSpawnUnitData[i].MaxForceLevel) )
		{
			`LOG("[PickBestDataSet()] Picked data set at index " $ i,, 'WotC_Gameplay_SupportStrikes');
			return default.arrSpawnUnitData[i];
		}
	}
	`LOG("[PickBestDataSet()] ERROR, no dataset was picked!",, 'WotC_Gameplay_SupportStrikes');
}

// Spawn a random unit into tactical mission
// Public because an event listener needs this
public static function XComGameState_Unit AddXComFriendliesToTactical(SpawnCharacterData CharTemplate, XComGameState NewGameState, Vector SpawnLocation, int GroupID, optional bool bIsCineActor = false)
{
	local XComGameStateHistory				History;
	local bool								bUsingStartState;
	local XComGameState_Unit				SpawnedUnit;
	local StateObjectReference				SpawnedUnitRef;
	local StateObjectReference				ItemReference;
	local XComGameState_Item				ItemState;
	local WeaponDataIntermediary			WeaponToAdd;
	local int								Idx;

	History = `XCOMHISTORY;

	bUsingStartState = (NewGameState == History.GetStartState());

	SpawnedUnitRef = `SPAWNMGR.CreateUnit( SpawnLocation, CharTemplate.TemplateName, eTeam_XCom, bUsingStartState, false, NewGameState, , CharTemplate.CharacterPoolName, false, , GroupID );
	SpawnedUnit = XComGameState_Unit(History.GetGameStateForObjectID(SpawnedUnitRef.ObjectID));
	SpawnedUnit.bMissionProvided = true;	//Mission provided so it doesn't count towards mission losses
//	SpawnedUnit.bTriggerRevealAI = false;	

	// add item states. This needs to be done so that the visualizer sync picks up the IDs and creates their visualizers -LEB
	foreach SpawnedUnit.InventoryItems(ItemReference)
	{
		ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemReference.ObjectID));
		ItemState.BeginTacticalPlay(NewGameState);   // this needs to be called explicitly since we're adding an existing state directly into tactical
		NewGameState.AddStateObject(ItemState);

		// add any cosmetic items that might exists
		ItemState.CreateCosmeticItemUnit(NewGameState);
	}

	if (bIsCineActor)
		SpawnedUnit.SetUnitFloatValue('IsPilot', 1, eCleanup_Never);

	// Replace primary/secondary weapons if needed
	if (CharTemplate.WPNCategory != '' && default.arrRandomWeapons.Length > 0 && !bIsCineActor)
	{
		Idx = default.arrRandomWeapons.Find('Category', CharTemplate.WPNCategory);
		if (Idx != INDEX_NONE)
		{
			WeaponToAdd = default.arrRandomWeapons[Idx].arrWeapons[ `SYNC_RAND_STATIC(default.arrRandomWeapons.Length) ];
			if (WeaponToAdd.PriWeaponTemplate != '')
				class'X2Helpers_MiscFunctions'.static.GiveItem(WeaponToAdd.PriWeaponTemplate, SpawnedUnit, NewGameState);

			if (WeaponToAdd.SecWeaponTemplate != '')
				class'X2Helpers_MiscFunctions'.static.GiveItem(WeaponToAdd.SecWeaponTemplate , SpawnedUnit, NewGameState);
		}
	}

	// add abilities -LEB
	// Must happen after items are added, to do ammo merging properly. -LEB
	`TACTICALRULES.InitializeUnitAbilities(NewGameState, SpawnedUnit);

	// submit it -LEB
	NewGameState.AddStateObject(SpawnedUnit);
	XComGameStateContext_TacticalGameRule(NewGameState.GetContext()).UnitRef = SpawnedUnit.GetReference();
	
	//	I assume this triggers the unit's abilities that activate at "UnitPostBeginPlay"
	SpawnedUnit.BeginTacticalPlay(NewGameState); 

	`LOG("[AddXComFriendliesToTactical()] Spawned Unit: " $ SpawnedUnit.GetFullName() $ " Of Template: " $ SpawnedUnit.GetMyTemplate().DataName $ " with ObjectID " $ SpawnedUnit.ObjectID, , 'WotC_Gameplay_SupportStrikes');

	return SpawnedUnit;
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

		//Stay hidden until the Matinee plays
		XGUnit(SpawnedUnit.GetVisualizer()).m_bForceHidden = true;
	}
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
//	local XComGameState_HeadquartersXCom XComHQ;
//	local XComGameStateHistory History;
	local int i;

	Unit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
//	History = `XCOMHISTORY;

	//add actionpoints
	for(i=0;i<default.SpawnedUnit_StandardAP;i++) Unit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	for(i=0;i<default.SpawnedUnit_MovementOnlyAP;i++) Unit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);

//	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	//	add the newly spawned unit to the first empty squad slot so they appear walking out of Skyranger after the mission

//	XComHQ.Squad.AddItem(NewUnitRef);
	//XComHQ.Squad[XComHQ.Squad.Find('ObjectID', 0)].ObjectID = NewUnitRef.ObjectID;
}

defaultproperties
{
	SpawnedUnitValueName="SpawnedSquadUnitValue"

	EffectName="SpawnSquadEffect"
	DuplicateResponse=eDupe_Allow

	EncounterID = XComTrooperSwarm;
}