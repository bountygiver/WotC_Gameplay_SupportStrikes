class X2Effect_DummyTargetUnit extends X2Effect_Persistent config(GameCore);

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	ActionPoints.Length = 1;
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit UnitSelf;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	UnitSelf = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( UnitSelf != None )
	{
		UnitSelf = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitSelf.ObjectID));

		// Remove the dead unit from play
		`XEVENTMGR.TriggerEvent('UnitRemovedFromPlay', UnitSelf, UnitSelf, NewGameState);
	}
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	//local X2Action_MimicBeaconEnd MimicEndAction;
	//local XComGameState_Unit UnitState;

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);

	if (EffectApplyResult != 'AA_Success' || ActionMetadata.VisualizeActor == none)
	{
		return;
	}

	//MimicEndAction = X2Action_MimicBeaconEnd(class'X2Action_MimicBeaconEnd'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	class'X2Action_MimicBeaconEnd'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);

	//UnitState = XComGameState_Unit(ActionMetadata.StateObject_OldState);
}

//simulated function AddX2ActionsForVisualization_Sync( XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata )
//{
////	local X2Action_PlayAnimation AnimationAction;
//
//	super.AddX2ActionsForVisualization_Sync(VisualizeGameState, ActionMetadata);
//
////	AnimationAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
////	AnimationAction.Params.AnimName = class'X2Ability_ItemGrantedAbilitySet'.default.MIMIC_BEACON_START_ANIM;
////	AnimationAction.Params.BlendTime = 0.0f;
//}

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType)
{
	return DamageType == 'poison' ||
		   DamageType == 'fire' ||
		   DamageType == 'acid' ||
		   DamageType == class'X2Item_DefaultDamageTypes'.default.KnockbackDamageType ||
		   DamageType == 'psi' ||
		   DamageType == class'X2Item_DefaultDamageTypes'.default.ParthenogenicPoisonType ||
		   DamageType == 'stun';
}

function bool CanAbilityHitUnit(name AbilityName)
{
	return false;
}

function bool DoesEffectAllowUnitToBleedOut(XComGameState_Unit UnitState) {return false; }
function bool DoesEffectAllowUnitToBeLooted(XComGameState NewGameState, XComGameState_Unit UnitState) {return false; }

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "DummyTargetUnitEffect"
}