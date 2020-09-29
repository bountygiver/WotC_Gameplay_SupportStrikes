//---------------------------------------------------------------------------------------
//  FILE:    X2Action_Matinee_A10.uc
//  AUTHOR:  E3245
//  PURPOSE: Controls the A10 Thunderbolt II matinees
//           
class X2Action_Matinee_A10 extends X2Action_PlayMatinee config(GameData);

var string						MatineeCommentPrefix;

function Init()
{
	// Insert the map into streaming map array
	`MAPS.AddStreamingMap("CIN_Vehicle_Aircraft_A10", , , false).bForceNoDupe = true;

	// need to find the matinee before calling super, which will init it
	FindMatinee(MatineeCommentPrefix);

	super.Init();

	SetMatineeBase('CIN_Vehicle_Aircraft_A10_Base');
}

//We never time out
function bool IsTimedOut()
{
	return false;
}

event bool BlocksAbilityActivation()
{
	return true; // matinees should never permit interruption
}

private function FindMatinee(string MatineePrefix)
{
	local array<SequenceObject> FoundMatinees;
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
			`LOG("[X2Action_Matinee_A10.FindMatinee()] SUCCESS, Matinee found with prefix: " $ MatineePrefix,, 'WotC_Gameplay_SupportStrikes');

			Matinees.AddItem(Matinee);
			return;
		}
	}

	`LOG("[X2Action_Matinee_A10.FindMatinee()] ERROR, No matinee found with prefix: " $ MatineePrefix $ "!",, 'WotC_Gameplay_SupportStrikes');
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
		Sleep(0.01f);
	}
	
	CompleteAction();
}

function CompleteAction()
{
	`LOG("[X2Action_Matinee_A10::" $ GetFuncName() $ "] No more matinees to play, closing action.",,'WotC_Gameplay_SupportStrikes');

	super.CompleteAction();
	EndMatinee();
	XComTacticalController(GetALocalPlayerController()).SetCinematicMode(false, true, true, true, true, true);
}



DefaultProperties
{
}
