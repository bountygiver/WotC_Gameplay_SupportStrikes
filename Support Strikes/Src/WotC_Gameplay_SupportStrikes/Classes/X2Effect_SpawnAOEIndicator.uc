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
var bool bIsLine;			// Will need custom calculations to properly display in the correct rotation

var string OverrideVFXPath;

private function DoTargetFX(XComGameState_Effect TargetEffect, out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context, name EffectApplyResult, bool bStopEffect)
{
	local X2Action_PlayEffect	EffectAction;
	local vector				UnitLocation;

	if( EffectApplyResult != 'AA_Success')
		return;

	if (VFXPath == "")
	{
		`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] VFX was not found.", class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(true),'WotC_Gameplay_SupportStrikes');
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

		// Needs proper rotation if this is a line ability
		if (bIsLine)
		{
			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Unit Template: " $ XComGameState_Unit(ActionMetadata.StateObject_NewState).GetMyTemplateName(), true,'WotC_Gameplay_SupportStrikes');
			UnitLocation = `XWORLD.GetPositionFromTileCoordinates(XComGameState_Unit(ActionMetadata.StateObject_NewState).TileLocation);

			EffectAction.EffectLocation = UnitLocation;
			EffectAction.EffectRotation = Rotator(TargetEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0] - UnitLocation);

			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Rotation: (" $ EffectAction.EffectRotation.Pitch $ ", " $ EffectAction.EffectRotation.Yaw $ ", " $ EffectAction.EffectRotation.Roll $ ")", true,'WotC_Gameplay_SupportStrikes');
		}
		else
		{
			EffectAction.EffectLocation = TargetEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
		}

		`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Applied Effect: " $ EffectAction.EffectName $ " to world.", bStopEffect && class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(,false) ,'WotC_Gameplay_SupportStrikes');
	}
	else
	{
		`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] TargetLocations is empty.",class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(true),'WotC_Gameplay_SupportStrikes');
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

// Call the same function again and recreate the ParticleSystem
simulated function SpawnAOEIndicatorSyncVisualizationFn(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	DoTargetFX(RemovedEffect, ActionMetadata, VisualizeGameState.GetContext(), EffectApplyResult, true);
}

defaultproperties
{
	EffectName="SpawnAOEIndicator"
	OverrideVFXPath=""
	EffectSyncVisualizationFn=SpawnAOEIndicatorSyncVisualizationFn
}