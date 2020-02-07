class X2Ability_StrafingRun extends X2Ability
	config(GameData_SupportStrikes);

var config int StrafingRun_A10_Local_Cooldown;				//
var config int StrafingRun_A10_Global_Cooldown;			//
var config int StrafingRun_A10_Delay_Turns;				// Number of turns before the next ability will fire
var config int StrafingRun_A10_LostSpawnIncreasePerUse;	// Increases the number of lost per usage
var config bool StrafingRun_A10_Panic_Enable;
var config int StrafingRun_A10_Panic_NumOfTurns;

var config int StrafingRun_A10_TileWidth;
var config int StrafingRun_A10_Range;

var config bool StrafingRun_A10_Disorient_Enable;
var config int StrafingRun_A10_Disorient_NumOfTurns;

var name StrafingRun_A10_Stage1_DirSlcTriggerName;
var name StrafingRun_A10_Stage1_DirSlcAbilityName;
var name StrafingRun_A10_Stage1_LocSelectEffectName;

var name StrafingRun_A10_Stage2_FinalTriggerName;

var name StrafingRun_A10_Stage2_FinalAbilityName;


static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage1_SelectLocation());	//Primer
	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage1_SelectAngle());	//The final confirmation ability

	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage2());

	Templates.AddItem(CreateDummyTarget_Initialize());

	return Templates;
}


//
// STRAFING RUN
//

/*
	 How this ability is set up:
	 1) The user picks a target location
	 2) The user picks the target direction
	 3) PROFIT!
*/

static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_Stage1_SelectLocation()
{
	local X2AbilityTemplate						Template;
//	local X2AbilityCost_ActionPoints			ActionPointCost;
//	local X2AbilityCooldown_LocalAndGlobal		Cooldown;
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Condition_Visibility				VisibilityCondition;
	local X2Condition_UnitProperty				UnitPropertyCondition;
	local X2Effect_SpawnAOEIndicator			StrafingRun_A10_Stage1TargetEffect;
//	local X2AbilityCost_Ammo					AmmoCost;
	local X2Condition_MapCheck					MapCheck;
	local X2Effect_Persistent					PersistentLocation;
	//local X2Effect_ApplyWeaponDamage			DamageEffect;
	local X2Effect_SpawnDummyTarget				SpawnDummyTarget;


	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Air_Off_StrafingRun_Stage1_SelectLocation');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	//CursorTarget.bRestrictToSquadsightRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.TargetingMethod = class'X2TargetingMethod_Pillar';

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = 0.25;
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

//	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
//	Cooldown.iNumTurns = default.StrafingRun_A10_Local_Cooldown;
//	Cooldown.NumGlobalTurns = default.StrafingRun_A10_Global_Cooldown;
//	Template.AbilityCooldown = Cooldown;

	PersistentLocation = new class'X2Effect_Persistent';
	PersistentLocation.EffectName = default.StrafingRun_A10_Stage1_LocSelectEffectName;
	Template.AddShooterEffect(PersistentLocation);

	/* BEGIN Shooter Conditions */

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	//Prevent the ability from executing if certain maps are loaded.
	MapCheck = new class'X2Condition_MapCheck';
	Template.AbilityShooterConditions.AddItem(MapCheck);

	//Exclude dead units from using this ability
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	/* END Shooter Conditions */

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bVisibleToAnyAlly = true;
	VisibilityCondition.bRequireLOS = false;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	// Effects
	SpawnDummyTarget = new class'X2Effect_SpawnDummyTarget';
	SpawnDummyTarget.GiveItemName = 'Support_Air_Offensive_StrafingRun_A10_T1_Strike';
	SpawnDummyTarget.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd); //Make effect wear off at end of turn or when the angle is set
	Template.AddShooterEffect(SpawnDummyTarget);

	//  Spawn the spinny circle doodad
	StrafingRun_A10_Stage1TargetEffect = new class'X2Effect_SpawnAOEIndicator';
	StrafingRun_A10_Stage1TargetEffect.OverrideVFXPath = "XV_SupportStrike_ParticleSystems.ParticleSystems.facingWaypoint_Icon_Red";
	Template.AddShooterEffect(StrafingRun_A10_Stage1TargetEffect);

	Template.bSkipFireAction = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = SR_Stage1_SpawnUnit_BuildVisualization;
	
	return Template;
}

simulated function SR_Stage1_SpawnUnit_BuildVisualization(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata ActionMetadata;

	local XComGameStateHistory			History;
	local XComGameStateContext_Ability	Context;
	local XComGameState_Unit			SourceUnit, SpawnedUnit;
	local UnitValue						SpawnedUnitValue;

	//class'X2Ability'.static.TypicalAbility_BuildVisualization(VisualizeGameState);

	History = `XCOMHISTORY;
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	// Configure the visualization track for the mimic beacon
	//******************************************************************************************
	SourceUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));

	if(SourceUnit != none)
	{
		`LOG("SourceUnit for Spawn Dummy Target viz: " @ SourceUnit.GetFullName(),, 'IRI_SUPPORT_STRIKES');
		SourceUnit.GetUnitValue(class'X2Effect_SpawnDummyTarget'.default.SpawnedUnitValueName, SpawnedUnitValue);

		if (SpawnedUnitValue.fValue != 0)
		{
			SpawnedUnit = XComGameState_Unit(History.GetGameStateForObjectID(SpawnedUnitValue.fValue,, VisualizeGameState.HistoryIndex));

			if (SpawnedUnit != none)
			{
				ActionMetadata.StateObject_OldState = SpawnedUnit;
				ActionMetadata.StateObject_NewState = SpawnedUnit;
				ActionMetadata.VisualizeActor = History.GetVisualizer(SpawnedUnit.ObjectID);

				class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(ActionMetadata, Context);

				class'X2Action_SyncVisualizer'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
			}
			else `LOG("No Spawned Unit for Spawn Dummy Target viz",, 'IRI_SUPPORT_STRIKES');
		}
		else `LOG("No Unit Value for Spawn Dummy Target viz",, 'IRI_SUPPORT_STRIKES');
	}
	else `LOG("Impossibruuuu, no Source Unit for Spawn Dummy Target viz",, 'IRI_SUPPORT_STRIKES');
}

//This is the first state of the mortar strike ability. It's purely to set up the strike with a timer before the next ability is triggered
static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_Stage1_SelectAngle()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTarget_Cursor				CursorTarget;
//	local X2Effect_SpawnAOEIndicator			StrafingRun_A10_Stage1TargetEffect;
	//local X2AbilityCost_SharedCharges			AmmoCost;
	//local X2Effect_ApplyWeaponDamage			DamageEffect;
	local X2AbilityMultiTarget_Line				LineMultiTarget;
	local X2Effect_IRI_DelayedAbilityActivation DelayEffect_StrafingRun;
	//local X2Effect_RemoveEffects				RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Air_Off_StrafingRun_Stage1_SelectAngle');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.Hostility = eHostility_Offensive;

	//	This ability is attached to a unit, not a weapon on the unit. Can't have ammo.
	Template.bUseAmmoAsChargesForHUD = false;
	
	//	It'll be the only ability on the dummy unit, priority is irrelevant.
	//Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.FixedAbilityRange = default.StrafingRun_A10_Range;
	Template.AbilityTargetStyle = CursorTarget;

	LineMultiTarget = new class'X2AbilityMultiTarget_Line';
	LineMultiTarget.TileWidthExtension = default.StrafingRun_A10_TileWidth;
	LineMultiTarget.bSightRangeLimited = false;
	Template.AbilityMultiTargetStyle = LineMultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_Line';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//	Put your cooldowns and conditions on Select 1 or Stage 2.
	/*
	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.StrafingRun_A10_Local_Cooldown;
	Cooldown.NumGlobalTurns = default.StrafingRun_A10_Global_Cooldown;
	Template.AbilityCooldown = Cooldown;*/


	//	This Select 2 ability will be used by a dummy unit. It should not have ANY shooter conditions.
	/* BEGIN Shooter Conditions */
	/* END Shooter Conditions */

	//	This is a cursor-targeted ability, it cannot possibly have Target Conditions.

	//	With this you would be trying to remove the effect from the Dummy Unit. Won't work. 
	//RemoveEffects = new class'X2Effect_RemoveEffects';
	//RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpawnDummyTarget'.default.EffectName);
	//Template.AddShooterEffect(RemoveEffects);

	DelayEffect_StrafingRun = new class 'X2Effect_IRI_DelayedAbilityActivation';
	DelayEffect_StrafingRun.BuildPersistentEffect(default.StrafingRun_A10_Delay_Turns, false, false, false, eGameRule_PlayerTurnBegin);
	DelayEffect_StrafingRun.EffectName = 'SR_Stage1Delay';
	DelayEffect_StrafingRun.TriggerEventName = default.StrafingRun_A10_Stage2_FinalTriggerName;
	DelayEffect_StrafingRun.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddShooterEffect(DelayEffect_StrafingRun);

	//	Apply another effect here that will remove or kill or hide or teleport the unit immediately once this ability is activated.

	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	return Template;
}


//The actual ability
static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_Stage2()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTrigger_EventListener		DelayedEventListener;
	local X2Effect_RemoveEffects				RemoveEffects;
	local X2Effect_ApplyWeaponDamage			DamageEffect;
//	local X2AbilityMultiTarget_Radius			RadMultiTarget;
	//local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityToHitCalc_StandardAim		StandardAim;
	/* Temp Shit */
	local X2AbilityMultiTarget_Line				LineMultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
//	local X2Condition_Visibility				VisibilityCondition;
	local X2Condition_UnitProperty				UnitPropertyCondition;
	local X2Effect_PersistentStatChange			DisorientedEffect;
	local X2Effect_Panicked						PanickedEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.StrafingRun_A10_Stage2_FinalAbilityName);
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	//	Targeting and Triggering - same as for Select 2
	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.FixedAbilityRange = default.StrafingRun_A10_Range;
	Template.AbilityTargetStyle = CursorTarget;

	LineMultiTarget = new class'X2AbilityMultiTarget_Line';
	LineMultiTarget.TileWidthExtension = default.StrafingRun_A10_TileWidth;
	LineMultiTarget.bSightRangeLimited = false;
	Template.AbilityMultiTargetStyle = LineMultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_Line';

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIndirectFire = true;
	StandardAim.bAllowCrit = false;	//	E3245 - up to you if you want this to crit or not.
	Template.AbilityToHitCalc = StandardAim;
	
	//	Multi Target Conditions
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
    UnitPropertyCondition.ExcludeDead = false;
    UnitPropertyCondition.ExcludeFriendlyToSource = false;
    UnitPropertyCondition.ExcludeHostileToSource = false;
    UnitPropertyCondition.FailOnNonUnits = false;
	UnitPropertyCondition.ExcludeInStasis = false;
    Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	Template.CinescriptCameraType = "MortarStrikeFinal";

	//	DEBUG ONLY - REMOVE
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	//	--


	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.StrafingRun_A10_Stage2_FinalTriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_None;	//	other filters don't work with effect-triggered event.
	DelayedEventListener.ListenerData.EventFn = StrafingRun_Listener;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

	//	Should not be here unless you want Mortars to stop firing if the soldier becomes disoriented or something like that.
	//Template.AddShooterEffectExclusions();

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

//
//	Template.bDontDisplayInAbilitySummary = true;
//	

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpawnAOEIndicator'.default.EffectName);
	Template.AddShooterEffect(RemoveEffects);

	// Damage and effects
	// The MultiTarget Units are dealt this damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bExplosiveDamage = true;
	DamageEffect.bIgnoreBaseDamage = false;
	//DamageEffect.EffectDamageValue = class'X2Item_SupportStrikes'.default.StrafingRun_A10_T1_BaseDamage;
	DamageEffect.bApplyWorldEffectsForEachTargetLocation = true;
	Template.AddMultiTargetEffect(DamageEffect);

	//	These have to be Multi Target effects, this attack has no primary target.
	if (default.StrafingRun_A10_Panic_Enable)
	{

		//  Panic effect
		PanickedEffect = class'X2StatusEffects'.static.CreatePanickedStatusEffect();
		PanickedEffect.iNumTurns = default.StrafingRun_A10_Panic_NumOfTurns;
		PanickedEffect.MinStatContestResult = 2;
		PanickedEffect.MaxStatContestResult = 3;
		Template.AddMultiTargetEffect(PanickedEffect);

	}

	if (default.StrafingRun_A10_Disorient_Enable)
	{
		//  Disorient effect
		DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect();
		DisorientedEffect.iNumTurns = default.StrafingRun_A10_Disorient_NumOfTurns;
		DisorientedEffect.MinStatContestResult = 1;
		DisorientedEffect.MaxStatContestResult = 1;
		Template.AddMultiTargetEffect(DisorientedEffect);
	}

	Template.ActionFireClass = class'X2Action_MortarStrikeStageTwo';
	Template.bSkipExitCoverWhenFiring = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.LostSpawnIncreasePerUse = default.StrafingRun_A10_LostSpawnIncreasePerUse;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

static function EventListenerReturn StrafingRun_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit				SourceUnit;
	//local XComGameState_Unit				OwnerUnit;
	local ApplyEffectParametersObject		AEPObject;
	local XComGameState_Ability				MortarAbilityState;
	local GameRulesCache_Unit				UnitCache;
	local int								i;
	//local UnitValue							UV;
	//local int								HistoryIndex;
	//local XComGameStateContext_Ability		AbilityContext;
	
	SourceUnit = XComGameState_Unit(EventData);
	AEPObject = ApplyEffectParametersObject(EventSource);
	MortarAbilityState = XComGameState_Ability(CallbackData);

	`LOG("Strafing Run Listener triggerred. SourceUnit unit: " @ SourceUnit.GetFullName() @ "AEPObject:" @ AEPObject.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName @ AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations[0] @ MortarAbilityState.GetMyTemplateName(),, 'IRIMORTAR');
	
	if (SourceUnit == none || AEPObject == none || MortarAbilityState == none)
    {
		`LOG("Strafing Run Listener: something wrong, exiting.",, 'IRIMORTAR');
        return ELR_NoInterrupt;
    }
	/*
	if (!SourceUnit.GetUnitValue('Support_Strike_Dummy_Target_SourceUnitID', UV))
	{
		`LOG("Strafing Run Listener: could not get Unit Value from spawned unit.",, 'IRIMORTAR');
        return ELR_NoInterrupt;
	}
	OwnerUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(MortarAbilityState.OwnerStateObject.ObjectID));
	if (OwnerUnit == none || MortarAbilityState.OwnerStateObject.ObjectID != UV.fValue)
	{
		//	Can happen if multiple soldiers carry Mortar Strike calldown weapon.
		`LOG("Strafing Run Listener: ability doesn't belong to a unit that summoned this dummy target, or there is no owner unit (nani?!) exiting.",, 'IRIMORTAR');
		return ELR_NoInterrupt;
	}*/

	if (MortarAbilityState.OwnerStateObject.ObjectID != SourceUnit.ObjectID)
	{
		//	Can happen if multiple soldiers carry Mortar Strike calldown weapon.
		`LOG("Strafing Run Listener: ability belongs to another unit, exiting.",, 'IRIMORTAR');
		return ELR_NoInterrupt;
	}
	
	//HistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
	if (`TACTICALRULES.GetGameRulesCache_Unit(SourceUnit.GetReference(), UnitCache))	//we get UnitCache for the soldier that triggered this event
	{
		for (i = 0; i < UnitCache.AvailableActions.Length; ++i)	//then in all actions available to them
		{
			if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == MortarAbilityState.ObjectID)	//we find our Mortar Stage 2 ability
			{
				`LOG("Strafing Run Listener: found Stage 2 ability.",, 'IRIMORTAR');
				if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')	// check that it succeeds all shooter conditions
				{
					// SPT_BeforeParallel - makes projectiles drop all at once, but bad viz
					if (class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i],, AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations,,,, /*HistoryIndex*/,, /*SPT_BeforeParallel*/))
					{
						`LOG("Strafing Run Listener: fire in the hole!",, 'IRIMORTAR');
					}
					else
					{
						`LOG("Strafing Run Listener: could not activate ability.",, 'IRIMORTAR');
					}
				}
				else
				{
					`LOG("Strafing Run Listener: it cannot be activated currently!",, 'IRIMORTAR');
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

// Special ability for the dummy target
// It's immune to everything, can't be hit, and has code required for removal.
static function X2AbilityTemplate CreateDummyTarget_Initialize()
{
	local X2AbilityTemplate Template;
	local X2Effect_DummyTargetUnit DummyImmunityEffect;
	local X2Effect_VanishNoBlocking VanishEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DummyTargetInitialize');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the immunities
	DummyImmunityEffect = new class'X2Effect_DummyTargetUnit';
	DummyImmunityEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Template.AddShooterEffect(DummyImmunityEffect);

	// Cosmetic vanish effect so the unit doesn't reveal by accident
	VanishEffect = new class'X2Effect_VanishNoBlocking';
	VanishEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Template.AddTargetEffect(VanishEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

defaultproperties
{
	StrafingRun_A10_Stage2_FinalAbilityName		= "Ability_Support_Land_Off_StrafingRun_A10_Stage2"
	StrafingRun_A10_Stage2_FinalTriggerName		= "Trigger_Support_Land_Off_StrafingRun_A10_Stage2"
	StrafingRun_A10_Stage1_LocSelectEffectName	= "Effect_Support_Land_Off_StrafingRun_A10_Stage1"
}