
//
//  AUTHOR: E3245
//	DESC:	Similar to X2Effect_SpawnMimicBeacon but does not contain code that creates doppelganger
//

class X2Effect_SpawnDummyTarget extends X2Effect_SpawnUnit;

var name GiveItemName;

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


//		Both of these seem to be never called.
//	Remove all abilities except 1, and make the ability the Select 2
/*
simulated function ModifyAbilitiesPreActivation(StateObjectReference NewUnitRef, out array<AbilitySetupData> AbilityData, XComGameState NewGameState)
{
	local AbilitySetupData SetupData;

	`LOG("Modifying abilities for newly-spawned Dummy Target",, 'IRI_SUPPORT_STRIKES');

	SetupData.TemplateName = 'Ability_Support_Air_Off_StrafingRun_Stage1_SelectAngle';
	SetupData.Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('Ability_Support_Air_Off_StrafingRun_Stage1_SelectAngle');
	SetupData.SourceWeaponRef.ObjectID = 0;
	SetupData.SourceAmmoRef.ObjectID = 0;

	AbilityData.AddItem(SetupData);
}
*/
/*
simulated function ModifyItemsPreActivation(StateObjectReference NewUnitRef, XComGameState NewGameState)
{
	local XComGameState_Unit	UnitState;
	local XComGameState_Item	ItemState;
	local X2EquipmentTemplate	ItemTemplate;

	// Remove all utility, secondary weapon, and heavy weapon items from the Ghost
	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));

	if (GiveItemName != '')
	{
		ItemTemplate = X2EquipmentTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(GiveItemName));
		`LOG("Adding item to Spawned Unit: " @ GiveItemName @ ItemTemplate.InventorySlot,, 'IRI_SUPPORT_STRIKES');

		if (ItemTemplate != none)
		{
			ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
			
			if (UnitState.AddItemToInventory(ItemState, ItemTemplate.InventorySlot, NewGameState))
			{
				`LOG("Success",, 'IRI_SUPPORT_STRIKES');
			}
			else `LOG("Fail",, 'IRI_SUPPORT_STRIKES');
		}
	}

}*/

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
	SelfUnit.SetUnitFloatValue('Support_Strike_Dummy_Target_SourceUnitID', SourceUnitGameState.ObjectID, eCleanup_BeginTactical);

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
	UnitToSpawnName="Support_Strikes_Dummy_Target"
	bKnockbackAffectsSpawnLocation=false
}