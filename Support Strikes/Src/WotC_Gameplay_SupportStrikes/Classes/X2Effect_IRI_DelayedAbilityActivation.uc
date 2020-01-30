// AUTHOR: Iridar
class X2Effect_IRI_DelayedAbilityActivation extends X2Effect_DelayedAbilityActivation;

static private function TriggerAssociatedEvent(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit				SourceUnit;
	local X2Effect_DelayedAbilityActivation DelayedEffect;
	local ApplyEffectParametersObject		AEPObject;

	DelayedEffect = X2Effect_DelayedAbilityActivation(PersistentEffect);

	AEPObject = new class'ApplyEffectParametersObject';
	AEPObject.ApplyEffectParameters = ApplyEffectParameters;

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	`LOG("Delayed Effect: triggering event:" @ DelayedEffect.TriggerEventName,, 'IRIMORTAR');

	`XEVENTMGR.TriggerEvent(DelayedEffect.TriggerEventName, SourceUnit, AEPObject, NewGameState);
}