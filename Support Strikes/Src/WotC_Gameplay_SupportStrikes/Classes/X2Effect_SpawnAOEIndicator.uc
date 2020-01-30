//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_SpawnAOEIndicator extends X2Effect_Persistent config(GameData);

var config string VFXPath;

var string OverrideVFXPath;

private function DoTargetFX(XComGameState_Effect TargetEffect, out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context, name EffectApplyResult, bool bStopEffect)
{
	local X2Action_PlayEffect EffectAction;

	if( EffectApplyResult != 'AA_Success')
		return;

	if (VFXPath == "")
	{
		`LOG("[X2Effect_SpawnAOEIndicator::DoTargetFX()] VFX was not found.", class'X2DownloadableContentInfo_WotC_SupportStrikes'.default.bLog,'WotC_Gameplay_SupportStrikes');
		return;
	}

	if( TargetEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations.Length > 0 )
	{
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		EffectAction.EffectName = default.VFXPath;

		if (default.OverrideVFXPath != "")
			EffectAction.EffectName = default.OverrideVFXPath;

		EffectAction.bStopEffect = bStopEffect;
		EffectAction.EffectLocation = TargetEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];

		`LOG("[X2Effect_SpawnAOEIndicator::DoTargetFX()] Applied Effect: " $ default.VFXPath $ " to world.", bStopEffect && class'X2DownloadableContentInfo_WotC_SupportStrikes'.default.bLog ,'WotC_Gameplay_SupportStrikes');
		`LOG("[X2Effect_SpawnAOEIndicator::DoTargetFX()] Removed Effect: " $ default.VFXPath $ " to world.", !bStopEffect && class'X2DownloadableContentInfo_WotC_SupportStrikes'.default.bLog ,'WotC_Gameplay_SupportStrikes');
	}
	else
	{
		`LOG("[X2Effect_SpawnAOEIndicator::DoTargetFX()] TargetLocations is empty.",,'WotC_Gameplay_SupportStrikes');
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local XComGameState_Effect TargetEffect;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', TargetEffect)
	{
		if( TargetEffect.GetX2Effect() == self )
		{
			break;
		}
	}

	if( TargetEffect == none )
	{
		`RedScreen("Could not find Spawn AOE Indicator effect. Report this bug if you see it.");
		return;
	}

	DoTargetFX(TargetEffect, ActionMetadata, VisualizeGameState.GetContext(), EffectApplyResult, false);
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	DoTargetFX(RemovedEffect, ActionMetadata, VisualizeGameState.GetContext(), EffectApplyResult, true);
}

defaultproperties
{
	EffectName="SpawnAOEIndicator"
	OverrideVFXPath=""
}