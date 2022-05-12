//---------------------------------------------------------------------------------------
// FILE:	X2Ability_MortarStrikes.uc
// AUTHOR:	E3245 & Iridar
// DESC:	Ability that calls and drops mortars at a specified area. 
//			The Mortars use a Event Listener to delay the strike while storing an AEP 
//			object to get the location of the strike when triggered
//
//---------------------------------------------------------------------------------------
class X2Ability_MortarStrikes extends X2Ability_SupportStrikes_Common
	config(GameData_SupportStrikes);

var config int MortarStrike_HE_Local_Cooldown;				//
var config int MortarStrike_HE_Global_Cooldown;				//
var config int MortarStrike_HE_Delay_Turns;					// Number of turns before the next ability will fire
var config int MortarStrike_HE_LostSpawnIncreasePerUse;		// Increases the number of lost per usage
var config int MortarStrike_HE_AdditionalSalvo_Turns;		// Number of turns that this ability will execute after the intial delay
var config int MortarStrike_HE_Shells_Per_Turn;

var config bool MortarStrike_HE_Panic_Enable;
var config int MortarStrike_HE_Panic_NumOfTurns;

var config bool MortarStrike_HE_Disorient_Enable;
var config int MortarStrike_HE_Disorient_NumOfTurns;

var config int MortarStrike_SMK_Local_Cooldown;				//
var config int MortarStrike_SMK_Global_Cooldown;			//
var config int MortarStrike_SMK_Delay_Turns;				// Number of turns before the next ability will fire
var config int MortarStrike_SMK_LostSpawnIncreasePerUse;	// Increases the number of lost per usage
var config int MortarStrike_SMK_AdditionalSalvo_Turns;		// Number of turns that this ability will execute after the intial delay
var config int MortarStrike_SMK_Shells_Per_Turn;

var config int MortarStrike_SMK_InitialCharges;

var config int MortarStrike_SMK_HitMod;

var config bool MortarStrike_SMK_EnableAlphaSmokeEffect;
var config int MortarStrike_SMK_AimMod;
var config array<name> MortarStrike_SMK_EffectsToCleanse;
var config array<name> MortarStrike_SMK_AbilitiesToDisableWhileInSmoke;

var config bool bEnableSmokeTileVisualization;

enum eMortarEffect
{
	eME_Explosive,
	eME_Smoke,
	eME_Flash,
	eME_None
};

var name MortarStrike_Stage1_HE_EffectName;

var name MortarStrike_Stage2_HE_TriggerAbilityName;
var name MortarStrike_Stage2_HE_ProjectileAbilityName;
var name MortarStrike_Stage2_HE_TriggerName;
var name MortarStrike_Stage2_HE_IndicatorEffectName;

var name MortarStrike_Stage2_SMK_TriggerAbilityName;
var name MortarStrike_Stage2_SMK_ProjectileAbilityName;
var name MortarStrike_Stage2_SMK_TriggerName;
var name MortarStrike_Stage2_SMK_IndicatorEffectName;

var localized string MortarStrike_Stage2_SMK_EffectDisplayName;
var localized string MortarStrike_Stage2_SMK_EffectDisplayDesc;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage1('Ability_Support_Land_Off_MortarStrike_HE_Stage1', eME_Explosive));
	Templates.AddItem(CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage2());
	Templates.AddItem(CreateSupport_Artillery_Offensive_MortarStrike_HE_Projectile());

	Templates.AddItem(CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage1('Ability_Support_Land_Def_MortarStrike_SMK_Stage1', eME_Smoke));
	Templates.AddItem(CreateSupport_Artillery_Defensive_MortarStrike_SMK_Stage2());
	Templates.AddItem(CreateSupport_Artillery_Defensive_MortarStrike_SMK_Projectile());

	return Templates;
}

//
// MORTAR STRIKE
//

//This is the first state of the mortar strike ability. It's purely to set up the strike with a timer before the next ability is triggered
static function X2DataTemplate CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage1(name TemplateName, eMortarEffect EffectCase)
{
	local X2AbilityTemplate						Template;
	local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal_All	Cooldown;
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Effect_IRI_DelayedAbilityActivation DelayEffect_MortarStrike;
	local X2Condition_Visibility				VisibilityCondition;
	local int									idx;
	local name									EffectName;
	local X2Effect_SpawnAOEIndicator			MortarStrike_HE_Stage1TargetEffect;
	local X2AbilityCost_SharedCharges			AmmoCost;
	local X2Condition_MapCheck					MapCheck;
	local X2Condition_ResourceCost				IntelCostCheck;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_platform_stability"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//Conceal until the strike hits
	Template.ConcealmentRule = eConceal_Always;

	//The weapon template has the actual amount of ammo
	Template.bUseAmmoAsChargesForHUD = true;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	//Ammo Cost
	AmmoCost = new class'X2AbilityCost_SharedCharges';	
    AmmoCost.NumCharges = 1;
	AmmoCost.bIncludeThisAbility = true;
	Template.AbilityCosts.AddItem(AmmoCost);

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	//CursorTarget.bRestrictToSquadsightRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bUseWeaponRadius = true;
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//	Ability Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal_All';

	/* BEGIN Shooter Conditions */

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	//Prevent the ability from executing if certain maps are loaded.
	MapCheck = new class'X2Condition_MapCheck';
	Template.AbilityShooterConditions.AddItem(MapCheck);

	IntelCostCheck = new class'X2Condition_ResourceCost';
	Template.AbilityShooterConditions.AddItem(IntelCostCheck);

	/* END Shooter Conditions */

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bVisibleToAnyAlly = true;
	VisibilityCondition.bRequireLOS = false;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	MortarStrike_HE_Stage1TargetEffect = new class'X2Effect_SpawnAOEIndicator';

	switch (EffectCase)
	{
		case (eME_Explosive):
			//  Spawn the spinny circle doodad
			MortarStrike_HE_Stage1TargetEffect.BuildPersistentEffect(default.MortarStrike_SMK_Delay_Turns + (default.MortarStrike_SMK_AdditionalSalvo_Turns + 1), false, false, false, eGameRule_PlayerTurnBegin);
			MortarStrike_HE_Stage1TargetEffect.EffectName = default.MortarStrike_Stage2_HE_IndicatorEffectName;
			Template.AddShooterEffect(MortarStrike_HE_Stage1TargetEffect);

			Cooldown.iNumTurns = default.MortarStrike_HE_Local_Cooldown;
			Cooldown.NumGlobalTurns = default.MortarStrike_HE_Global_Cooldown;

			//Delayed Effect to cause the second Mortar Strike stage to occur
			for (idx = 0; idx < (default.MortarStrike_HE_AdditionalSalvo_Turns + 1); ++idx)
			{
				EffectName = name("MortarStrikeStage1Delay_" $ 0);

				DelayEffect_MortarStrike = new class 'X2Effect_IRI_DelayedAbilityActivation';
				DelayEffect_MortarStrike.BuildPersistentEffect(default.MortarStrike_HE_Delay_Turns + idx, false, false, false, eGameRule_PlayerTurnBegin);
				DelayEffect_MortarStrike.EffectName = EffectName;
				DelayEffect_MortarStrike.TriggerEventName = default.MortarStrike_Stage2_HE_TriggerName;
				DelayEffect_MortarStrike.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
				Template.AddShooterEffect(DelayEffect_MortarStrike);
			}
			break;
		case (eME_Smoke):
			//  Spawn the spinny circle doodad
			MortarStrike_HE_Stage1TargetEffect.BuildPersistentEffect(default.MortarStrike_SMK_Delay_Turns + (default.MortarStrike_SMK_AdditionalSalvo_Turns + 1), false, false, false, eGameRule_PlayerTurnBegin);
			MortarStrike_HE_Stage1TargetEffect.EffectName = default.MortarStrike_Stage2_SMK_IndicatorEffectName;
			MortarStrike_HE_Stage1TargetEffect.OverrideVFXPath = "XV_SupportStrike_ParticleSystems.ParticleSystems.P_SupportStrike_AOE_Defensive";
			Template.AddShooterEffect(MortarStrike_HE_Stage1TargetEffect);

			Cooldown.iNumTurns = default.MortarStrike_SMK_Local_Cooldown;
			Cooldown.NumGlobalTurns = default.MortarStrike_SMK_Global_Cooldown;

			//Delayed Effect to cause the second Mortar Strike stage to occur
			for (idx = 0; idx < (default.MortarStrike_SMK_AdditionalSalvo_Turns + 1); ++idx)
			{
				EffectName = name("MortarStrikeSmokeStage1Delay_" $ idx);

				DelayEffect_MortarStrike = new class 'X2Effect_IRI_DelayedAbilityActivation';
				DelayEffect_MortarStrike.BuildPersistentEffect(default.MortarStrike_SMK_Delay_Turns + idx, false, false, false, eGameRule_PlayerTurnBegin);
				DelayEffect_MortarStrike.EffectName = EffectName;
				DelayEffect_MortarStrike.TriggerEventName = default.MortarStrike_Stage2_SMK_TriggerName;
				DelayEffect_MortarStrike.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
				Template.AddShooterEffect(DelayEffect_MortarStrike);
			}
			break;
		default:
			break;
	}

	// Reserved in the ability trigger as an EL that will intercept the Scatter mod
	Template.AbilityTriggers.AddItem(CreateFixScatterZLevelEventListener());

	Template.AbilityCooldown = Cooldown;

	Template.BuildNewGameStateFn = TypicalSupportStrike_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.AlternateFriendlyNameFn = TypicalSupportStrike_AlternateFriendlyName;
	
	return Template;
}

// Let this ability perform a multi-ability trigger
static function X2DataTemplate CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage2()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    DelayedEventListener;

	Template = PurePassive(default.MortarStrike_Stage2_HE_TriggerAbilityName, "img:///UILibrary_PerkIcons.UIPerk_platform_stability", false, 'eAbilitySource_Item');

	// Wipe the purepassive's original abilitytrigger
	Template.AbilityTriggers.Length = 0;

	// This ability fires when the event DelayedExecuteRemoved fires on this unit. We will take care of the Gamestates ourselves
	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.MortarStrike_Stage2_HE_TriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_None;	//	other filters don't work with effect-triggered event.
	DelayedEventListener.ListenerData.EventFn = static.Mortar_Listener;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

	Template.BuildNewGameStateFn = Empty_BuildGameState;

	return Template;	
}

simulated function XComGameState Empty_BuildGameState(XComGameStateContext Context)
{
	//	This is an explicit placeholder so that ValidateTemplates doesn't think something is wrong with the ability template.
	`RedScreen("This function should never be called.");
	return none;
}

//The actual ability
static function X2DataTemplate CreateSupport_Artillery_Offensive_MortarStrike_HE_Projectile()
{
	local X2AbilityTemplate						Template;
	local X2Effect_RemoveEffects				RemoveEffects;
	local X2Effect_ApplyWeaponDamage			DamageEffect;
	local X2AbilityToHitCalc_StandardAim		StandardAim;
	/* Temp Shit */
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Condition_UnitProperty				UnitPropertyCondition;
	local X2Effect_PersistentStatChange			DisorientedEffect;
	local X2Effect_Panicked						PanickedEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.MortarStrike_Stage2_HE_ProjectileAbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_bigbooms"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//Conceal until the strike hits
	Template.ConcealmentRule = eConceal_Never;

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;
	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bUseWeaponRadius = true;
//	MultiTarget.fTargetHeight = 10;
	Template.AbilityMultiTargetStyle = MultiTarget;

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIndirectFire = true;
	StandardAim.bAllowCrit = false;
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
	Template.bDontDisplayInAbilitySummary = true;

	// Reserved in the ability trigger as an EL that will intercept the Scatter mod
	Template.AbilityTriggers.AddItem(CreateFixScatterZLevelEventListener());

	// No one should trigger this ability
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

//	RemoveEffects = new class'X2Effect_RemoveEffects';
//	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpawnAOEIndicator'.default.EffectName);
//	Template.AddShooterEffect(RemoveEffects);

	// Damage and effects
	// The MultiTarget Units are dealt this damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bExplosiveDamage = true;
	DamageEffect.bIgnoreBaseDamage = false;
	DamageEffect.bApplyWorldEffectsForEachTargetLocation = true;
	Template.AddMultiTargetEffect(DamageEffect);

	if (default.MortarStrike_HE_Panic_Enable)
	{

		//  Panic effect
		PanickedEffect = class'X2StatusEffects'.static.CreatePanickedStatusEffect();
		PanickedEffect.iNumTurns = default.MortarStrike_HE_Panic_NumOfTurns;
		PanickedEffect.MinStatContestResult = 2;
		PanickedEffect.MaxStatContestResult = 3;
		Template.AddTargetEffect(PanickedEffect);

	}

	if (default.MortarStrike_HE_Disorient_Enable)
	{
		//  Disorient effect
		DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect();
		DisorientedEffect.iNumTurns = default.MortarStrike_HE_Disorient_NumOfTurns;
		DisorientedEffect.MinStatContestResult = 1;
		DisorientedEffect.MaxStatContestResult = 1;
		Template.AddTargetEffect(DisorientedEffect);
	}

	Template.ActionFireClass = class'X2Action_MortarStrikeStageTwo';
	Template.bSkipExitCoverWhenFiring = true;

	Template.BuildNewGameStateFn 	= TypicalAbility_BuildGameState;
	Template.ModifyNewContextFn		= Mortar_Stage2_ModifyActivatedAbilityContext;
	Template.BuildVisualizationFn 	= Mortar_Stage2_BuildVisualization;
	Template.MergeVisualizationFn 	= Mortar_Stage2_MergeVisualization;

	Template.LostSpawnIncreasePerUse = default.MortarStrike_HE_LostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	Template.AssociatedPlayTiming = SPT_BeforeParallel;

	return Template;
}

static function X2Effect SmokeMortarEffect()
{
	local X2Effect_SmokeMortar Effect;

	Effect = new class'X2Effect_SmokeMortar';
	//Must be at least as long as the duration of the smoke effect on the tiles. Will get "cut short" when the tile stops smoking or the unit moves. -btopp 2015-08-05
	Effect.BuildPersistentEffect(class'X2Effect_ApplySmokeMortarToWorld'.default.Duration + 1, false, false, false, eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, default.MortarStrike_Stage2_SMK_EffectDisplayName, default.MortarStrike_Stage2_SMK_EffectDisplayDesc, "img:///UILibrary_PerkIcons.UIPerk_grenade_smoke", true);
	Effect.HitMod				= default.MortarStrike_SMK_HitMod;
	Effect.AimBonus				= default.MortarStrike_SMK_AimMod;
	Effect.bAlphaSmokeEffect	= default.MortarStrike_SMK_EnableAlphaSmokeEffect;
	Effect.EffectsToRemove		= default.MortarStrike_SMK_EffectsToCleanse;
	Effect.EffectTickedFn		= SmokeEffectTicked;
	Effect.DuplicateResponse	= eDupe_Refresh;
	return Effect;
}

function bool SmokeEffectTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
    local XComGameState_Unit SourceUnit;

 
    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
    if (SourceUnit != none)
		//Obviously, remove the effect if the Source Unit is not in the proper smoked tile
		if (!SourceUnit.IsInWorldEffectTile(class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name))
			return true;

    return false; //  do not end the effect
}

// Let this ability perform a multi-ability trigger
static function X2DataTemplate CreateSupport_Artillery_Defensive_MortarStrike_SMK_Stage2()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    DelayedEventListener;

	Template = PurePassive(default.MortarStrike_Stage2_SMK_TriggerAbilityName, "img:///UILibrary_PerkIcons.UIPerk_platform_stability", false, 'eAbilitySource_Item');

	// Wipe the purepassive's original abilitytrigger
	Template.AbilityTriggers.Length = 0;

	// This ability fires when the event DelayedExecuteRemoved fires on this unit. We will take care of the Gamestates ourselves
	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.MortarStrike_Stage2_SMK_TriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_None;	//	other filters don't work with effect-triggered event.
	DelayedEventListener.ListenerData.EventFn = static.Mortar_Listener;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

	Template.BuildNewGameStateFn = Empty_BuildGameState;

	return Template;	
}

//Smoke explosion ability
static function X2DataTemplate CreateSupport_Artillery_Defensive_MortarStrike_SMK_Projectile()
{
	local X2AbilityTemplate						Template;
	local X2Effect_RemoveEffects				RemoveEffects;
	local X2AbilityToHitCalc_StandardAim		StandardAim;
	/* Temp Shit */
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Condition_UnitProperty				UnitPropertyCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.MortarStrike_Stage2_SMK_ProjectileAbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_bigbooms";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//Conceal until the strike hits
	Template.ConcealmentRule = eConceal_Never;

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;
	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bUseWeaponRadius = true;
//	MultiTarget.fTargetHeight = 10;
	Template.AbilityMultiTargetStyle = MultiTarget;

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIndirectFire = true;
	StandardAim.bAllowCrit = false;
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
//
//	Template.bDontDisplayInAbilitySummary = true;
//	
	// No one should trigger this ability
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	// Reserved in the ability trigger as an EL that will intercept the Scatter mod
	Template.AbilityTriggers.AddItem(CreateFixScatterZLevelEventListener());

//	RemoveEffects = new class'X2Effect_RemoveEffects';
//	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpawnAOEIndicator'.default.EffectName);
//	Template.AddShooterEffect(RemoveEffects);

	// Damage and effects

	Template.AddMultiTargetEffect(new class'X2Effect_ApplySmokeMortarToWorld');
	//The actual smoke effect
	Template.AddMultiTargetEffect(SmokeMortarEffect());

	Template.ActionFireClass = class'X2Action_MortarStrikeStageTwo';
	Template.bSkipExitCoverWhenFiring = true;

	Template.BuildNewGameStateFn 	= TypicalAbility_BuildGameState;
	Template.ModifyNewContextFn		= Mortar_Stage2_ModifyActivatedAbilityContext;
	Template.BuildVisualizationFn 	= Mortar_Stage2_BuildVisualization;
	Template.MergeVisualizationFn 	= Mortar_Stage2_MergeVisualization;

	Template.LostSpawnIncreasePerUse = default.MortarStrike_SMK_LostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	// Run in parallel so it's super quick
	Template.AssociatedPlayTiming = SPT_BeforeParallel;

	return Template;
}

static function Mortar_Stage2_ModifyActivatedAbilityContext(XComGameStateContext Context)
{
	local XComGameStateContext_Ability	AbilityContext;

	AbilityContext = XComGameStateContext_Ability(Context);

	// Store the initial location for the camera action
	AbilityContext.InputContext.ProjectileTouchStart = AbilityContext.InputContext.TargetLocations[0];
}

static function Mortar_Stage2_BuildVisualization(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata		ActionMetadata;
	local XComGameStateHistory				History;
	local XComGameStateContext_Ability		Context;
	local X2Action_CameraLookAt				LookAtTargetAction;
	local X2Action_TimedWait				WaitAction;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());	

	ActionMetadata.StateObjectRef = Context.InputContext.SourceObject;
	ActionMetadata.VisualizeActor = History.GetVisualizer(ActionMetadata.StateObjectRef.ObjectID);
	History.GetCurrentAndPreviousGameStatesForObjectID(ActionMetadata.StateObjectRef.ObjectID,
													   ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState,
													   eReturnType_Reference,
													   VisualizeGameState.HistoryIndex);
	
	// Randomly wait a few seconds before firing off a mortar
	WaitAction = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, Context));
	WaitAction.DelayTimeSec = `SYNC_FRAND_STATIC(20) + (`SYNC_FRAND_STATIC(3) + 1.0f);	//Use Float Random to have more variety
	
	// Look at the place where the mortar is firing from
	// This will get replaced during the merge viz for all contexts with bSkipAdditionalVisualizationSteps
	LookAtTargetAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	LookAtTargetAction.LookAtLocation = Context.InputContext.ProjectileTouchStart;
	LookAtTargetAction.LookAtDuration = 3.00f;
	LookAtTargetAction.TargetZoomAfterArrival = 1.00f;

	//FIRE IN THE HOLE!
	TypicalAbility_BuildVisualization(VisualizeGameState);
}

/*
simulated function LookAtLocation_PostBuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability	Context;	
	local X2Action_CameraLookAt			LookAtTargetAction;
	local XComGameState_Effect			AOEEffectState;
	local XComGameState_Unit			SourceUnitState;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local array<X2Action>				FoundActions;
	local X2Action						TestMarkerAction;
	//`LOG("Calling Dynamic Deployment Build Viz function", bLog, 'IRIDAR');

	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	SourceUnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	AOEEffectState = SourceUnitState.GetUnitAffectedByEffectState(class'X2Effect_SpawnAOEIndicator'.default.EffectName);

	if( AOEEffectState == none )
	{
		`LOG("[LookAtLocation_PostBuildVisualization] No AOE Effect Exists!",, 'WotC_Gameplay_SupportStrikes');
		return;
	}

	VisualizationMgr.GetNodesOfType(VisualizationMgr.BuildVisTree, class'X2Action_MarkerNamed', FoundActions);
	foreach FoundActions(TestMarkerAction)
	{
		LookAtTargetAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.CreateVisualizationAction(Context));
		LookAtTargetAction.LookAtLocation = AOEEffectState.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
		LookAtTargetAction.LookAtDuration = 6.00f;
		VisualizationMgr.ReplaceNode(TestMarkerAction, LookAtTargetAction);
	}
}
*/

// Removes the camera from the other actions
simulated function Mortar_Stage2_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr VisMgr;
	local XComGameStateContext_Ability 	CurrentAbilityContext;
	local Array<X2Action> 				TestActions;
	local X2Action 						TestMarkerAction;
	local X2Action_MarkerNamed 			CameraReplaceAction;

	VisMgr = `XCOMVISUALIZATIONMGR;

	CurrentAbilityContext = XComGameStateContext_Ability(BuildTree.StateChangeContext);

	// The rest of the contexes. The zeroth one is our master context where all others will merge into
	if( CurrentAbilityContext.bSkipAdditionalVisualizationSteps )
	{
		// we only need one LookAt, so replace all the others with filler
		if( VisualizationTree != None )
		{
			VisMgr.GetNodesOfType(BuildTree, class'X2Action_CameraLookAt', TestActions);
			foreach TestActions(TestMarkerAction)
			{
				CameraReplaceAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.CreateVisualizationAction(CurrentAbilityContext));
				CameraReplaceAction.SetName("MortarStrikeCameraLookAtReplacement");
				VisMgr.ReplaceNode(CameraReplaceAction, TestMarkerAction);
			}
		}
	}

	// We still need to merge
	CurrentAbilityContext.SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
}

static function EventListenerReturn Mortar_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit				SourceUnit;
	local ApplyEffectParametersObject		AEPObject;
	local XComGameState_Ability				MortarAbilityState;

	SourceUnit = XComGameState_Unit(EventData);
	AEPObject = ApplyEffectParametersObject(EventSource);

	`LOG("Mortar Listener triggerred. SourceUnit unit: " @ SourceUnit.GetFullName() @ "AEPObject:" @ AEPObject.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName @ AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations[0] @ MortarAbilityState.GetMyTemplateName(),, 'IRIMORTAR');
	
	if (SourceUnit == none || AEPObject == none)
    {
		`LOG("Mortar Listener: AEP Missing: " $ AEPObject == none $ "SourceUnit missing: " $ SourceUnit == none ,, 'IRIMORTAR');
        return ELR_NoInterrupt;
    }

	// Attempt to fetch the stage 2 projectile ability
	switch (AEPObject.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName)
	{
		case 'Ability_Support_Land_Off_MortarStrike_HE_Stage1':
			MortarAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.FindAbility(default.MortarStrike_Stage2_HE_ProjectileAbilityName).ObjectID));
			break;
		case 'Ability_Support_Land_Def_MortarStrike_SMK_Stage1':
			MortarAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.FindAbility(default.MortarStrike_Stage2_SMK_ProjectileAbilityName).ObjectID));
			break;
	}

	// Exit if we have no AbilityState to work with
	if (MortarAbilityState == none)
		return ELR_NoInterrupt;
	else if (MortarAbilityState != none && MortarAbilityState.OwnerStateObject.ObjectID != SourceUnit.ObjectID)
	{
		//	Can happen if multiple soldiers carry Mortar Strike calldown weapon.
		`LOG("Mortar Listener: ability belongs to another unit, exiting.",, 'IRIMORTAR');
		return ELR_NoInterrupt;
	}
	
	TriggerMortarProjectileAbility(AEPObject, SourceUnit, MortarAbilityState);

	return ELR_NoInterrupt;
}

static function TriggerMortarProjectileAbility(ApplyEffectParametersObject AEPObject, XComGameState_Unit SourceUnit, XComGameState_Ability MortarAbilityState)
{
	local array<ActionSelection> 			SelectedAbilities;
	local ActionSelection 					SelectAction;
	local AvailableTarget					Target;
	local int j;

	// Clear any previous entities
	SelectedAbilities.Length = 0;

	// THis data is immutable between indices
	SelectAction.PerformAction.AbilityObjectRef			= MortarAbilityState.GetReference();
	SelectAction.PerformAction.AvailableCode 			= MortarAbilityState.CanActivateAbility(SourceUnit);
	SelectAction.TargetLocations						= AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations;
	
	// Gather all targets in location
	MortarAbilityState.GatherAdditionalAbilityTargetsForLocation(SelectAction.TargetLocations[0], Target);
		
	// Set the current target as gathered from the abilitystate
	SelectAction.PerformAction.AvailableTargets.AddItem(Target);

	// Generate the list of abilities to trigger this ability
	for (j = 0; j < default.MortarStrike_HE_Shells_Per_Turn; j++)
	{
		SelectedAbilities.AddItem(SelectAction);
	}
	
	// Activate the abilities at the current index
	if( SelectedAbilities.Length > 0 )
	{
		class'XComGameStateContext_Ability'.static.ActivateAbilityList(SelectedAbilities, `XCOMHISTORY.GetCurrentHistoryIndex(), true, SPT_BeforeParallel);
	}
}

defaultproperties
{
	MortarStrike_Stage2_HE_TriggerAbilityName		= "Ability_Support_Land_Off_MortarStrike_HE_Stage2_Trigger"
	MortarStrike_Stage2_HE_ProjectileAbilityName	= "Ability_Support_Land_Off_MortarStrike_HE_Stage2_Projectile"
	MortarStrike_Stage2_HE_TriggerName				= "Trigger_Support_Land_Off_MortarStrike_HE_Stage2"
	MortarStrike_Stage2_HE_IndicatorEffectName		= "Mortar_HE_IndicatorEffect"

	MortarStrike_Stage2_SMK_TriggerAbilityName		= "Ability_Support_Land_Def_MortarStrike_SMK_Stage2"
	MortarStrike_Stage2_SMK_ProjectileAbilityName	= "Ability_Support_Land_Def_MortarStrike_SMK_Stage2_Projectile"
	MortarStrike_Stage2_SMK_TriggerName				= "Trigger_Support_Land_Def_MortarStrike_SMK_Stage2"
	MortarStrike_Stage2_SMK_IndicatorEffectName		= "Mortar_SMK_IndicatorEffect"

	MortarStrike_Stage1_HE_EffectName="Effect_Support_Land_Off_MortarStrike_HE_Stage1"
}