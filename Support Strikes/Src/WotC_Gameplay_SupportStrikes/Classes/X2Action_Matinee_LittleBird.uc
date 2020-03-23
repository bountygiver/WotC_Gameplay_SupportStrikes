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

var private array<StateObjectReference> MatineeUnitRefs;
var private array<StateObjectReference> CleanUpUnitRefs;

function Init()
{
	// need to find the matinee before calling super, which will init it
	FindMatinee(MatineeCommentPrefix);

	super.Init();

	`LOG("[X2Action_Matinee_LittleBird.Init()] Recorded SourceUnitID: " $ SourceUnitID,, 'WotC_Gameplay_SupportStrikes');

	RetrieveSourceUnit(StateChangeContext);

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
	local int UnitIndex, CineUnitIndex;
	local UnitValue PilotCheck;

	UnitIndex = 1;
	CineUnitIndex = 1;

	foreach InContext.AssociatedState.IterateByClassType(class'XComGameState_Unit', GameStateUnit)
	{
		//Skip over source unit
		if ( SourceUnitID == GameStateUnit.ObjectID )
			continue;

		GameStateUnit.GetUnitValue('IsPilot', PilotCheck);
		
		if ( PilotCheck.fValue > 0 ) // Is Pilot
		{
			// Pilots don't count towards the unit index, they have their own index
			AddUnitToMatinee(name("Pilot_0" $ CineUnitIndex), GameStateUnit);			
			`LOG("[X2Action_Matinee_LittleBird.AddUnitsToMatinee()] Adding " $ GameStateUnit.GetFullName() $ " of Object ID: " $ GameStateUnit.ObjectID $ " to Pilot_0" $ CineUnitIndex $ " slot.",, 'WotC_Gameplay_SupportStrikes');
			CineUnitIndex++;

			MatineeUnitRefs.AddItem(GameStateUnit.GetReference());
			CleanUpUnitRefs.AddItem(GameStateUnit.GetReference());
		}
		else	// Not a pilot
		{
			// Add units to both Fake and Real platform
			AddUnitToMatinee(name("F_Platform_0" $ UnitIndex), GameStateUnit);
			AddUnitToMatinee(name("R_Platform_0" $ UnitIndex), GameStateUnit);
			`LOG("[X2Action_Matinee_LittleBird.AddUnitsToMatinee()] Adding " $ GameStateUnit.GetFullName() $ " of Object ID: " $ GameStateUnit.ObjectID $ " to F_ and R_Platform_0" $ UnitIndex $ " slot.",, 'WotC_Gameplay_SupportStrikes');
			UnitIndex++;

			MatineeUnitRefs.AddItem(GameStateUnit.GetReference());
		}
	}

	`LOG("[X2Action_Matinee_LittleBird.AddUnitsToMatinee()] Non-cosmetic Units in matinee: " $ (UnitIndex - 1) $ ", Cosmetic Units in matinee: " $ (CineUnitIndex - 1),, 'WotC_Gameplay_SupportStrikes');

	// Fill in blank slots if Unit Index is less that NumDropSlots
	while( UnitIndex < NumDropSlots )
	{
		AddUnitToMatinee(name("F_Platform_0" $ UnitIndex), none);
		AddUnitToMatinee(name("R_Platform_0" $ UnitIndex), none);
		UnitIndex++;
	}

	// We started at 1, so we need to check if there's at least 3 indices
	while ( CineUnitIndex < 3 )
	{
		AddUnitToMatinee(name("Pilot_0" $ CineUnitIndex), none);			
		CineUnitIndex++;
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

//	GameSeq.FindSeqObjectsByName( DesiredMatineePrefix , true, FoundMatinees2, true, false );
//
//	if (FoundMatinees2.Length > 0)
//	{
//		`LOG("[X2Action_Matinee_LittleBird.FindMatinee()] FoundMatinees2.Length: " $ FoundMatinees2.Length);
//		for (Index = FoundMatinees2.length; Index > 0; Index--)
//		{
//			Matinee = SeqAct_Interp(FoundMatinees2[Index]);
//			`log("" $ Matinee.ObjComment,,'Matinee');
//		}
//	}


	//Search in reverse order, we're guarenteed to find our custom map the quickest
	for (Index = FoundMatinees.length - 1; Index >= 0; Index--)
	{
		Matinee = SeqAct_Interp(FoundMatinees[Index]);
		`log("" $ Matinee.ObjComment,,'Matinee');
		if( Instr(Matinee.ObjComment, DesiredMatineePrefix, , true) >= 0 )
		{
			`LOG("[X2Action_Matinee_LittleBird.FindMatinee()] SUCCESS, Matinee found with prefix: " $ MatineePrefix,, 'WotC_Gameplay_SupportStrikes');

			Matinees.AddItem(Matinee);
			return;
		}
	}

	`LOG("[X2Action_Matinee_LittleBird.FindMatinee()] ERROR, No matinee found with prefix: " $ MatineePrefix $ "!",, 'WotC_Gameplay_SupportStrikes');
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
}

function CompleteAction()
{
	local XComGameState_Unit			UnitState;
	local VisualizationActionMetadata	ActionMetadata;
	local StateObjectReference			UnitRef;
	local XComWorldData					WorldData;
	local XGUnit						XGUnitToDelete;
	local XComUnitPawn					XComUnitPawnToDelete;

	super.CompleteAction();

	WorldData = `XWORLD;

	// If the game crashes it's because of this
	`LOG("[X2Action_Matinee_LittleBird.CompleteAction()] Cleaning up and deleting Cinematic Units.",, 'WotC_Gameplay_SupportStrikes');

	//Delete the pilots from the game, they don't serve any purpose
	foreach CleanUpUnitRefs(UnitRef)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		if (UnitState == none)
			continue;

		WorldData.UnregisterActor(ActionMetadata.VisualizeActor);
		`XCOMHISTORY.SetVisualizer(UnitState.ObjectID, none); //Let the history know that we are destroying this visualizer

		XGUnitToDelete = XGUnit(ActionMetadata.VisualizeActor);
		XComUnitPawnToDelete = XGUnitToDelete.GetPawn();

		//Destroy Unit Pawn
		XComUnitPawnToDelete.Destroy();

		//Destroy XGUnit
		XGUnitToDelete.Destroy();	

		`LOG("[X2Action_Matinee_LittleBird.CompleteAction()] Success, Deleted cinematic actor from tactical.",, 'WotC_Gameplay_SupportStrikes');
	}
}



DefaultProperties
{
}
