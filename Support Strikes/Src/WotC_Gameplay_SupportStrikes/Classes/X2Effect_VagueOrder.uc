//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Effect_Obsessed.uc    
//  AUTHOR:  David Burchanowski  --  10/3/2016
//  PURPOSE: Panic Effects - Remove control from player and run Panic behavior tree.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_VagueOrder extends X2Effect_Persistent;

var name Order;
var int ActionPoints;
/*
//•	Vague Orders
//	o	If XCom Triggers a specific ability (separate implementation), then the unit will be granted this effect and do whatever XCom tells them to do.
//	o	Coming soon
function bool TickVagueOrder(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Unit TargetUnit;
	local Name PanicBehaviorTree;
	local XComGameStateHistory History;
	local int Point;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	//If the current turn is the Resistance member and this unit is on the resistance team
	if (UnitState.GetTeam() == eTeam_Resistance && `TACTICALRULES.GetUnitActionTeam() == eTeam_Resistance)
	{
		// Must add action points for the behavior tree run to work.
		for (Point = 0; Point < ActionPoints; ++Point)
		{
			if (Point < UnitState.ActionPoints.Length)
			{
				if (UnitState.ActionPoints[Point] != class'X2CharacterTemplateManager'.default.StandardActionPoint)
				{
					UnitState.ActionPoints[Point] = class'X2CharacterTemplateManager'.default.StandardActionPoint;
				}
			}
			else
			{
				UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
			}
		}

		// Delayed behavior tree kick-off.  Points must be added and game state submitted before the behavior tree can 
		// update, since it requires the ability cache to be refreshed with the new action points.
//		UnitState.AutoRunBehaviorTree(Order, BTRunCount, `XCOMHISTORY.GetCurrentHistoryIndex() + 1, true);
	}
	else
	{
		return true; // End this effect if the target is dead.
	}

	return false;
}

defaultproperties
{
	EffectTickedFn = TickVagueOrder
	ActionPoints = 2
}

*/