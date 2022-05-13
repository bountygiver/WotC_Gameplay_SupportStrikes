
//
//  AUTHOR: E3245
//	DESC:	Similar to X2Effect_SpawnMimicBeacon but does not contain code that creates doppelganger
//

class X2Effect_SpawnDummyTarget extends X2Effect_SpawnUnit;

function vector GetSpawnLocation(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	if(ApplyEffectParameters.AbilityInputContext.TargetLocations.Length == 0)
	{
		`LOG("Attempting to create X2Effect_SpawnDummyTarget without a target location!",, 'IRI_SUPPORT_STRIKES');
		return vect(0,0,0);
	}

	return ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
}

// Get the team that this unit should be added to
function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return GetSourceUnitsTeam(ApplyEffectParameters, true);
}

function TriggerSpawnEvent(const out EffectAppliedData ApplyEffectParameters, XComGameState_Unit EffectTargetUnit, XComGameState NewGameState, XComGameState_Effect EffectGameState)
{
	super.TriggerSpawnEvent(ApplyEffectParameters, EffectTargetUnit, NewGameState, EffectGameState);
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit 	SelfUnit, SourceUnitGameState;
	local X2EventManager		EventManager;
	local EffectAppliedData 	NewEffectParams;
	local X2Effect 				SireZombieEffect;
	local Object				SelfObject;

	SourceUnitGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( SourceUnitGameState == none)
	{
		SourceUnitGameState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID, eReturnType_Reference));
	}

	if (NewUnitRef.ObjectID == 0)
	{
		`RedScreenOnce(GetFuncName() $ ": Unit was not created properly. This may cause the ability to break!");
		return;
	}

	SelfUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', NewUnitRef.ObjectID));

	// ----------------------------------------------------------------------------------------------------------------
	// X2Effect_SpawnMimicBeacon:
	// UI update happens in quite a strange order when squad concealment is broken.
	// The unit which threw the mimic beacon will be revealed, which should reveal the rest of the squad.
	// The mimic beacon won't be revealed properly unless it's considered to be concealed in the first place.
	// ----------------------------------------------------------------------------------------------------------------

	//SelfUnit.bRequiresVisibilityUpdate = true;

	if (SourceUnitGameState.IsSquadConcealed())
		SelfUnit.SetIndividualConcealment(true, NewGameState); //Don't allow the mimic beacon to be non-concealed in a concealed squad.

	// Nullify any Concealment Event Listeners so it cannot reveal itself to the enemy
	SelfObject = SelfUnit;
	EventManager = `XEVENTMGR;
//
	EventManager.UnregisterFromEvent(SelfObject, 'ObjectMoved', ELD_OnStateSubmitted);		
	EventManager.UnregisterFromEvent(SelfObject, 'UnitMoveFinished', ELD_OnStateSubmitted);
//
//	// Better safe than sorry
	EventManager.UnregisterFromEvent(SelfObject, 'EffectBreakUnitConcealment', ELD_OnStateSubmitted);

	SelfUnit.bRequiresVisibilityUpdate = true;

	// Register an event listener that destroys this unit at the end of the players turn if they have not triggered the second ability

	// Create a Sire link effect to the unit that spawned this effect
	// Link the source and zombie
//	NewEffectParams = ApplyEffectParameters;
//	NewEffectParams.EffectRef.ApplyOnTickIndex = INDEX_NONE;
//	NewEffectParams.EffectRef.LookupType = TELT_AbilityTargetEffects;
//	NewEffectParams.EffectRef.SourceTemplateName = class'X2Ability_Sectoid'.default.SireZombieLinkName;
//	NewEffectParams.EffectRef.TemplateEffectLookupArrayIndex = 0;
//	NewEffectParams.TargetStateObjectRef = SelfUnit.GetReference();
//
//	SireZombieEffect = class'X2Effect'.static.GetX2Effect(NewEffectParams.EffectRef);
//	SireZombieEffect.ApplyEffect(NewEffectParams, SelfUnit, NewGameState);
}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationActionMetadata SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationActionMetadata EffectTargetUnitTrack)
{
	local X2Action_SelectNextActiveUnitTriggerUI 	SelectUnitAction;

	// Sync up visualizer. This will unhide the unit
//	class'X2Action_SyncVisualizer'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded);
	class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded);

	// Force the Tactical Controller to switch to this unit
	SelectUnitAction = X2Action_SelectNextActiveUnitTriggerUI(class'X2Action_SelectNextActiveUnitTriggerUI'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded));
	SelectUnitAction.TargetID = SpawnedUnitTrack.StateObject_NewState.ObjectID;
}

defaultproperties
{
	bKnockbackAffectsSpawnLocation=false
}