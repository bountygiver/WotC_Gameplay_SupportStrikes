class X2Effect_VanishNoBlocking extends X2Effect_Vanish;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	//Effects that change visibility must actively indicate it
	kNewTargetState.bRequiresVisibilityUpdate = true;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata BuildTrack, name EffectApplyResult)
{
	local X2Action_ForceUnitVisiblity ForceVisiblityAction;

	super.AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, EffectApplyResult);

	ForceVisiblityAction = X2Action_ForceUnitVisiblity(class'X2Action_ForceUnitVisiblity'.static.AddToVisualizationTree(BuildTrack, VisualizeGameState.GetContext()));
	ForceVisiblityAction.ForcedVisible = eForceNotVisible;
}

function EGameplayBlocking ModifyGameplayDestinationBlockingForTarget(const XComGameState_Unit UnitState, const XComGameState_Unit TargetUnit) 
{
	return eGameplayBlocking_DoesNotBlock;
}
