//---------------------------------------------------------------------------------------
// FILE:	XComGameState_HeadquartersProjectStrikeDelay
// AUTHOR:	E3245
// DESC:	Basic project that unlocks the GTS perks once the timer runs out
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectStrikeDelay extends XComGameState_HeadquartersProject;

//Put key here to prevent certain strikes from getting bought while this project is active.
var name StrikeName;
var int AdditionalDays;

//---------------------------------------------------------------------------------------
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_GameTime TimeState;

	History = `XCOMHISTORY;

	ProjectFocus = FocusRef;

    bProgressesDuringFlight = true;
    bNoInterruptOnComplete = true;
	WorkPerHour = 1;
	InitialProjectPoints = 24;
	ProjectPointsRemaining = 24;

	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if(`STRATEGYRULES != none)
	{
		if(class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}

	SetProjectedCompletionDateTime(StartDateTime);

	`LOG("[SetProjectFocus()] Created " $ StrikeName $ " Project with Completion Date: " $ class'X2StrategyGameRulesetDataStructures'.static.GetDateString(CompletionDateTime) $ " " $ class'X2StrategyGameRulesetDataStructures'.static.GetTimeString(CompletionDateTime),,'WotC_Strategy_SupportStrikes');
}

function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	return 1;
}


//---------------------------------------------------------------------------------------
// Sets the project completion time under the current conditions
function SetProjectedCompletionDateTime(TDateTime StartTime)
{
	// start time + additional days that must be filled out
	CompletionDateTime = StartTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddDays(CompletionDateTime, AdditionalDays);
}

//---------------------------------------------------------------------------------------
// Just remove the project so the GTS perks get unlocked again
function OnProjectCompleted()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local string	strStrikeName;
	local string	strStrikeMsgFinal;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Strike Delay Project Completed");

	// Remove the project
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.Projects.RemoveItem(self.GetReference());
	NewGameState.RemoveStateObject(self.ObjectID);

	`LOG("[OnProjectCompleted()] Removed Delay Project from XComHQ",,'WotC_Strategy_SupportStrikes');

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// Notify the player that a support strike is available
	if (StrikeName == 'Artillery')
		strStrikeName = "Artillery"; 
	else if (StrikeName == 'IonCannon')
		strStrikeName = "Ion Cannon";
		
	strStrikeMsgFinal = strStrikeName $ " support now available for tasking.";
	
	`HQPRES.NotifyBanner("Support Strike Available", class'UIUtilities_IMage'.const.EventQueue_Resistance, `XEXPAND.ExpandString(strStrikeMsgFinal),, eUIState_Good);
}

//---------------------------------------------------------------------------------------
DefaultProperties
{

}
