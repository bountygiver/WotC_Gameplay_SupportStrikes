//---------------------------------------------------------------------------------------
//  FILE:    X2Action_ATT.uc
//  AUTHOR:  E3245
//  PURPOSE: Controls the custom AH-6 Little Bird Drop Off Matinee
//           
class X2Action_Matinee_LittleBird extends X2Action_PlayMatinee config(GameData);

var const config string MatineeCommentPrefix;
var const config int NumDropSlots;				//Usually (4 * 2) + 2

// Store this here so we can make sure the source unit doesn't get added to the matinee
var int SourceUnitID;

// These refs will be set invisible after the matinee is complete
var private array<StateObjectReference> MatineeUnitRefs;
var private array<StateObjectReference> CleanUpUnitRefs;

function Init()
{
	// Insert the map into streaming map array
	`MAPS.AddStreamingMap("CIN_Vehicle_Aircraft_LittleBird", , , false).bForceNoDupe = true;

	// need to find the matinee before calling super, which will init it
	FindMatinee(MatineeCommentPrefix);

	super.Init();

	RetrieveSourceUnit(StateChangeContext);

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Recorded SourceUnitID: " $ SourceUnitID,, 'WotC_Gameplay_SupportStrikes');

	AddUnitsToMatinee(StateChangeContext);

	SetMatineeBase('CIN_Vehicle_LBravo_Matinee_Base');
}

private function RetrieveSourceUnit(XComGameStateContext InContext)
{
	local XComGameState_Unit GameStateUnit;

	foreach InContext.AssociatedState.IterateByClassType(class'XComGameState_Unit', GameStateUnit)
	{
		SourceUnitID = GameStateUnit.ObjectID;
		break;
	}
}

private function AddUnitsToMatinee(XComGameStateContext InContext)
{
	local XComGameState_Unit GameStateUnit;
	local int UnitIndex, PilotIndex, CosmeticUnitIndex;

	UnitIndex = 1;
	PilotIndex = 1;
	CosmeticUnitIndex = 1;

	foreach InContext.AssociatedState.IterateByClassType(class'XComGameState_Unit', GameStateUnit)
	{
		//Skip over source unit
		if ( SourceUnitID == GameStateUnit.ObjectID )
			continue;


		`LOG("[X2Action_Matinee_LittleBird::" $ GetFuncName() $ "] " $ GameStateUnit.GetFullName() $ ", Tag: " $ GameStateUnit.TacticalTag , , 'WotC_Gameplay_SupportStrikes');
		
		if ( GameStateUnit.TacticalTag == 'SupportStrike_Pilot' ) // Is Pilot
		{
			// Pilots don't count towards the unit index, they have their own index
			AddUnitToMatinee(name("Pilot_0" $ PilotIndex), GameStateUnit);			
			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Adding " $ GameStateUnit.GetFullName() $ " of Object ID: " $ GameStateUnit.ObjectID $ " to Pilot_0" $ PilotIndex $ " slot.",, 'WotC_Gameplay_SupportStrikes');
			PilotIndex++;

			CleanUpUnitRefs.AddItem(GameStateUnit.GetReference());
		}
		else if ( GameStateUnit.TacticalTag == 'SupportStrike_Clone' ) // Is Cosmetic Unit
		{
			// Add units to the fake platform
			AddUnitToMatinee(name("F_Platform_0" $ CosmeticUnitIndex), GameStateUnit);

			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Adding " $ GameStateUnit.GetFullName() $ " of Object ID: " $ GameStateUnit.ObjectID $ " to F_Platform_0" $ CosmeticUnitIndex $ " slot.",, 'WotC_Gameplay_SupportStrikes');
			CosmeticUnitIndex++;

			CleanUpUnitRefs.AddItem(GameStateUnit.GetReference());
		}
		else
		{
			// Add combat units to the real platform
			AddUnitToMatinee(name("R_Platform_0" $ UnitIndex), GameStateUnit);

			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Adding " $ GameStateUnit.GetFullName() $ " of Object ID: " $ GameStateUnit.ObjectID $ " to R_Platform_0" $ UnitIndex $ " slot.",, 'WotC_Gameplay_SupportStrikes');
			UnitIndex++;

			MatineeUnitRefs.AddItem(GameStateUnit.GetReference());
		}
	}

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Pilots in matinee: " $ (PilotIndex - 1) ,, 'WotC_Gameplay_SupportStrikes');
	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Combat Units in matinee: " $ (UnitIndex - 1) ,, 'WotC_Gameplay_SupportStrikes');
	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Cosmetic Units in matinee: " $ (CosmeticUnitIndex - 1) ,, 'WotC_Gameplay_SupportStrikes');

	// Fill in blank slots if Unit Index is less that NumDropSlots
	while( UnitIndex < NumDropSlots )
	{
		AddUnitToMatinee(name("F_Platform_0" $ UnitIndex), none);
		AddUnitToMatinee(name("R_Platform_0" $ UnitIndex), none);
		UnitIndex++;
	}

	// We started at 1, so we need to check if there's at least 3 indices
	while ( PilotIndex < 3 )
	{
		AddUnitToMatinee(name("Pilot_0" $ PilotIndex), none);			
		PilotIndex++;
	}

}

//We never time out
function bool IsTimedOut()
{
	return false;
}

private function FindMatinee(string MatineePrefix)
{
	local array<SequenceObject> FoundMatinees;
//	local array<SequenceObject> FoundMatinees2;
	local SeqAct_Interp Matinee;
	local Sequence GameSeq;
	local int Index;
	local string DesiredMatineePrefix;

	DesiredMatineePrefix = MatineePrefix; // default to the general config data

	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	GameSeq.FindSeqObjectsByClass(class'SeqAct_Interp', true, FoundMatinees);

	//Search in reverse order, we're guarenteed to find our custom map the quickest
	for (Index = FoundMatinees.length - 1; Index >= 0; Index--)
	{
		Matinee = SeqAct_Interp(FoundMatinees[Index]);
		//`log("" $ Matinee.ObjComment,,'Matinee');
		if( Instr(Matinee.ObjComment, DesiredMatineePrefix, , true) >= 0 )
		{
			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] SUCCESS, Matinee found with prefix: " $ MatineePrefix,, 'WotC_Gameplay_SupportStrikes');

			Matinees.AddItem(Matinee);
			return;
		}
	}

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] ERROR, No matinee found with prefix: " $ MatineePrefix $ "!",, 'WotC_Gameplay_SupportStrikes');
	Matinee = none;
}

simulated state Executing
{
	simulated event BeginState(name PrevStateName)
	{
		super.BeginState(PrevStateName);
		
		`BATTLE.SetFOW(false);
	}

	simulated event EndState(name NextStateName)
	{

		super.EndState(NextStateName);

		`BATTLE.SetFOW(true);
	}

Begin:
	PlayMatinee();

	// just wait for the matinee to complete playback
	while(Matinees.Length > 0) // the matinees will be cleared when they are finished
	{
		Sleep(0.0f);
	}
	
	CompleteAction();
}



function CompleteAction()
{
	local XComGameState_Unit			UnitState;
	local StateObjectReference			UnitRef;
	local XComWorldData					WorldData;
	local XGUnit						XGUnitToDelete, ShownXGUnit;
	local XComUnitPawn					ShownUnitPawn, XComUnitPawnToDelete;
	local TTile							CurrentTile;

	`LOG("[X2Action_Matinee_LittleBird::" $ GetFuncName() $ "] No more matinees to play, closing action.",,'WotC_Gameplay_SupportStrikes');

	super.CompleteAction();
	EndMatinee();
	XComTacticalController(GetALocalPlayerController()).SetCinematicMode(false, true, true, true, true, true);

	// Intialize the animations for these units, the player or AI will want to use them immediately after the sequence
	foreach MatineeUnitRefs(UnitRef)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

		// This shouldn't happen but just in case
		if (UnitState == none)
			continue;

		// Get our variables ready
		ShownXGUnit = XGUnit(UnitState.GetVisualizer());
		ShownUnitPawn = ShownXGUnit.GetPawn();

		// Unhide the unit
		ShownXGUnit.m_bForceHidden = false;

		// If the unit wasn't frozen before (DLC_2) then unfreeze the unit
 		if( !UnitState.IsFrozen() )
 		{
			ShownUnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
		}

		//Restore animations 
		ShownUnitPawn.RestoreAnimSetsToDefault();
		ShownUnitPawn.UpdateAnimations();

		// Trigger the idle animation
		ShownXGUnit.IdleStateMachine.PlayIdleAnim();
		
		CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(Unit.Location);
		`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(ShownXGUnit, CurrentTile);
	}


	WorldData = `XWORLD;

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Cleaning up and deleting Cinematic Units.",, 'WotC_Gameplay_SupportStrikes');

	//Delete the pilots and cosmetic units from the tactical game, they don't serve any purpose
	foreach CleanUpUnitRefs(UnitRef)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		
		// This shouldn't happen but just in case
		if (UnitState == none)
			continue;

		// Remove the unit from play
		UnitState.RemoveUnitFromPlay();

		// Just in case the unit actually blocks the tile
		WorldData.ClearTileBlockedByUnitFlag(UnitState);

		//Stay hidden even after Matinee finishes playing
		XGUnitToDelete = XGUnit(UnitState.GetVisualizer());
		XGUnitToDelete.m_bForceHidden = true;

		//Prepare the unit for deletion
		WorldData.UnregisterActor(XGUnitToDelete);
		XComUnitPawnToDelete = XGUnitToDelete.GetPawn();

		//Destroy Unit Pawn
		XComUnitPawnToDelete.Destroy();

		//Destroy XGUnit
		XGUnitToDelete.Destroy();

		`LOG("[X2Action_Matinee_LittleBird.CompleteAction()] Success, Deleted " $ UnitState.TacticalTag $ ", " $ UnitState.GetFullName() $ " from tactical but not it's unitstate.",, 'WotC_Gameplay_SupportStrikes');
	}
}



DefaultProperties
{
}
