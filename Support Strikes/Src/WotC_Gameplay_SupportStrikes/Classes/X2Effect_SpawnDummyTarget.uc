
//
//  AUTHOR: E3245
//	DESC:	Similar to X2Effect_SpawnMimicBeacon but does not contain code that creates doppelganger
//

class X2Effect_SpawnDummyTarget extends X2Effect_SpawnUnit;

function vector GetSpawnLocation(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{

	if(ApplyEffectParameters.AbilityInputContext.TargetLocations.Length == 0)
	{
		`Redscreen("Attempting to create X2Effect_SpawnDummyTarget without a target location! @dslonneger");
		return vect(0,0,0);
	}

	return ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
}

// Get the team that this unit should be added to
function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return GetSourceUnitsTeam(ApplyEffectParameters);
}

function AddSpawnVisualizationsToTracks_Parent(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationActionMetadata SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, X2Action Parent)
{
	class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, Parent);
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit SelfUnit, SourceUnitGameState;

	SourceUnitGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( SourceUnitGameState == none)
	{
		SourceUnitGameState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID, eReturnType_Reference));
	}

	SelfUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));

	SelfUnit.ActionPoints.Length = 0;
	SelfUnit.SetUnitFloatValue('NewSpawnedUnit', 1, eCleanup_BeginTactical);

	// ----------------------------------------------------------------------------------------------------------------
	// X2Effect_SpawnMimicBeacon:
	// UI update happens in quite a strange order when squad concealment is broken.
	// The unit which threw the mimic beacon will be revealed, which should reveal the rest of the squad.
	// The mimic beacon won't be revealed properly unless it's considered to be concealed in the first place.
	// ----------------------------------------------------------------------------------------------------------------

	if (SourceUnitGameState.IsSquadConcealed())
		SelfUnit.SetIndividualConcealment(true, NewGameState); //Don't allow the mimic beacon to be non-concealed in a concealed squad.
}

defaultproperties
{
	UnitToSpawnName="DummyPiSTarget"
	bCopyTargetAppearance=false
	bKnockbackAffectsSpawnLocation=false
	EffectName="SpawnDummyTarget"
}