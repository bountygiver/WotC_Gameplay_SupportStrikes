//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCooldown_LocalAndGlobal_All.uc
//  Allows for cooldowns on an individual unit as well as shared among all units of this 
//  ability for one player.
//
//  EDITS: E3245
//	Allows players to also get global cooldowns, not just AI units.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCooldown_LocalAndGlobal_All extends X2AbilityCooldown;

var() int NumGlobalTurns;
var() int ReserveNumGlobalTurns;	// Used for abilities that do not apply cooldown on itself, by other abilities
var() int ReserveNumLocalTurns;

simulated function ApplyCooldown(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameState_Unit 	kUnitState;
	local XComGameState_Player 	kPlayerState;
	local XComGameStateHistory 	History;

	History = `XCOMHISTORY;

	super.ApplyCooldown(kAbility, AffectState, AffectWeapon, NewGameState);

	kUnitState = XComGameState_Unit(AffectState);
	kPlayerState = XComGameState_Player(History.GetGameStateForObjectID(kUnitState.ControllingPlayer.ObjectID));

	if( (kPlayerState != none) )
	{
		// If the player state is AI (alien or civilian) then use the NumGlobalTurns value
		kPlayerState = XComGameState_Player(NewGameState.ModifyStateObject(kPlayerState.Class, kPlayerState.ObjectID));
		kPlayerState.SetCooldown(kAbility.GetMyTemplateName(), NumGlobalTurns);
	}
}

// This avoids the main ApplyCooldown function when applying costs
simulated function ApplyCooldownExternal(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameState_Unit 	kUnitState;
	local XComGameState_Player 	kPlayerState;
	local XComGameStateHistory 	History;

	History = `XCOMHISTORY;

	kUnitState = XComGameState_Unit(AffectState);
	kPlayerState = XComGameState_Player(History.GetGameStateForObjectID(kUnitState.ControllingPlayer.ObjectID));

	kAbility.iCooldown 						= ReserveNumLocalTurns;

	ApplyAdditionalCooldown(kAbility, AffectState, AffectWeapon, NewGameState);

	if( (kPlayerState != none) )
	{
		// If the player state is AI (alien or civilian) then use the NumGlobalTurns value
		kPlayerState = XComGameState_Player(NewGameState.ModifyStateObject(kPlayerState.Class, kPlayerState.ObjectID));
		kPlayerState.SetCooldown(kAbility.GetMyTemplateName(), ReserveNumGlobalTurns);
	}
}