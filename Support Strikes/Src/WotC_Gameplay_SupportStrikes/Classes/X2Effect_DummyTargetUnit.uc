//
// AUTHOR:	E3245
// DESC:	Not to be confused with X2Effect_SpawnDummyTarget. 
//			This makes the unit immune to all effects in the game and kills the unit upon removal
//
class X2Effect_DummyTargetUnit extends X2Effect_Persistent config(GameCore);

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	//Effects that change visibility must actively indicate it
	kNewTargetState.bRequiresVisibilityUpdate = true;
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	//`LOG("EffectState FullTurnsTicked: " $ EffectState.FullTurnsTicked $ ", Initial ActionPoints: " $ ActionPoints.Length, true, 'WotC_Gameplay_SupportStrikes');

	ActionPoints.Length = 0;

	if (EffectState.FullTurnsTicked == 0)
	{
		ActionPoints.Length = 0;
		ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	}
	
	//`LOG("Final ActionPoints: " $ ActionPoints.Length, true, 'WotC_Gameplay_SupportStrikes');
}

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType) { return true; } // Cannot be damaged by anything
function bool CanAbilityHitUnit(name AbilityName) { return false; } // No hits 
function bool DoesEffectAllowUnitToBleedOut(XComGameState_Unit UnitState) { return false; }
function bool DoesEffectAllowUnitToBeLooted(XComGameState NewGameState, XComGameState_Unit UnitState) { return false; }
function EGameplayBlocking ModifyGameplayPathBlockingForTarget(const XComGameState_Unit UnitState, const XComGameState_Unit TargetUnit) { return eGameplayBlocking_DoesNotBlock; }
function EGameplayBlocking ModifyGameplayDestinationBlockingForTarget(const XComGameState_Unit UnitState, const XComGameState_Unit TargetUnit) { return ModifyGameplayPathBlockingForTarget(UnitState, TargetUnit); }
function bool AreMovesVisible() { return false; }
function ModifyGameplayVisibilityForTarget(out GameRulesCache_VisibilityInfo InOutVisibilityInfo, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit)
{
	// Invisible to everyone and allies to the enemy as to not break concealment
	InOutVisibilityInfo.bVisibleGameplay			= false;
	InOutVisibilityInfo.bVisibleBasic				= false;
	InOutVisibilityInfo.bClearLOS					= false;
	InOutVisibilityInfo.bVisibleFromDefault			= false;
	InOutVisibilityInfo.bVisibleToDefault			= false;
	InOutVisibilityInfo.bVisibleDefaultToDefault	= false;
	InOutVisibilityInfo.bConcealedTrace				= false;
	InOutVisibilityInfo.bTargetIsAlly				= true;
	InOutVisibilityInfo.GameplayVisibleTags.AddItem('RemovedFromPlay');
}

function EffectAddedCallback(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		ModifyTurnStartActionPoints(UnitState, UnitState.ActionPoints, none);
	}
}

function bool RetainIndividualConcealment(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return true; }

DefaultProperties
{
	EffectAddedFn=EffectAddedCallback
//	DuplicateResponse = eDupe_Ignore
	EffectName = "DummyTargetUnitEffect"
}