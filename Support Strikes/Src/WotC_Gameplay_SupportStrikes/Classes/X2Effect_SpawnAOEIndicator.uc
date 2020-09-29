//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

//
// AUTHOR:	E3245
// DESC:	Spawns a Particle System representing the AOE indicator. Can be used to spawn other PS.
//
//

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
		`LOG("[X2Effect_SpawnAOEIndicator::DoTargetFX()] VFX was not found.", class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(true),'WotC_Gameplay_SupportStrikes');
		return;
	}

	if( TargetEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations.Length > 0 )
	{
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));

		if (OverrideVFXPath != "")
			EffectAction.EffectName = OverrideVFXPath;
		else
			EffectAction.EffectName = default.VFXPath;

		EffectAction.bStopEffect = bStopEffect;
		EffectAction.EffectLocation = TargetEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];

		`LOG("[X2Effect_SpawnAOEIndicator::DoTargetFX()] Applied Effect: " $ EffectAction.EffectName $ " to world.", bStopEffect && class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(,false) ,'WotC_Gameplay_SupportStrikes');
	}
	else
	{
		`LOG("[X2Effect_SpawnAOEIndicator::DoTargetFX()] TargetLocations is empty.",class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(true),'WotC_Gameplay_SupportStrikes');
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