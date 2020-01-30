class X2Ability_StrafingRun extends X2Ability
	config(GameData_SupportStrikes);

var config int StrafingRun_A10_Local_Cooldown;				//
var config int StrafingRun_A10_Global_Cooldown;			//
var config int StrafingRun_A10_Delay_Turns;				// Number of turns before the next ability will fire
var config int StrafingRun_A10_LostSpawnIncreasePerUse;	// Increases the number of lost per usage
var config bool StrafingRun_A10_Panic_Enable;
var config int StrafingRun_A10_Panic_NumOfTurns;

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
//	local X2Effect_SpawnAOEIndicator			StrafingRun_A10_Stage1TargetEffect;
//	local X2AbilityCost_Ammo					AmmoCost;
	local X2Condition_MapCheck					MapCheck;
	local X2Effect_Persistent					PersistentLocation;
	local X2Effect_ApplyWeaponDamage			DamageEffect;


	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Air_Off_StrafingRun_Stage1_SelectLocation');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

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

	// Damage and effects
	// The MultiTarget Units are dealt this damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bExplosiveDamage = true;
	DamageEffect.bIgnoreBaseDamage = false;
	DamageEffect.bApplyWorldEffectsForEachTargetLocation = true;
	Template.AddMultiTargetEffect(DamageEffect);

	/* END Shooter Conditions */

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bVisibleToAnyAlly = true;
	VisibilityCondition.bRequireLOS = false;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	return Template;
}

//This is the first state of the mortar strike ability. It's purely to set up the strike with a timer before the next ability is triggered
static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_Stage1_SelectAngle()
{
	local X2AbilityTemplate						Template;
	local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal		Cooldown;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Condition_Visibility				VisibilityCondition;
//	local X2Effect_SpawnAOEIndicator			StrafingRun_A10_Stage1TargetEffect;
	local X2AbilityCost_SharedCharges			AmmoCost;
	local X2Condition_MapCheck					MapCheck;
	local X2Effect_ApplyWeaponDamage			DamageEffect;
	local X2AbilityMultiTarget_Line				LineMultiTarget;


	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Air_Off_StrafingRun_Stage1_SelectAngle');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//The weapon template has the actual amount of ammo
	Template.bUseAmmoAsChargesForHUD = true;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	//Ammo Cost
	AmmoCost = new class'X2AbilityCost_SharedCharges';	
	Template.AbilityCosts.AddItem(AmmoCost);

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	//CursorTarget.bRestrictToSquadsightRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	LineMultiTarget = new class'X2AbilityMultiTarget_Line';
	Template.AbilityMultiTargetStyle = LineMultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_Line';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//Use AP
	//	Ability Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.StrafingRun_A10_Local_Cooldown;
	Cooldown.NumGlobalTurns = default.StrafingRun_A10_Global_Cooldown;
	Template.AbilityCooldown = Cooldown;

	/* BEGIN Shooter Conditions */

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	//Prevent the ability from executing if certain maps are loaded.
	MapCheck = new class'X2Condition_MapCheck';
	Template.AbilityShooterConditions.AddItem(MapCheck);

	/* END Shooter Conditions */

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bVisibleToAnyAlly = true;
	VisibilityCondition.bRequireLOS = false;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	// Damage and effects
	// The MultiTarget Units are dealt this damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bExplosiveDamage = true;
	DamageEffect.bIgnoreBaseDamage = false;
	DamageEffect.bApplyWorldEffectsForEachTargetLocation = true;
	Template.AddMultiTargetEffect(DamageEffect);

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
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
//	local X2Condition_Visibility				VisibilityCondition;
	local X2Condition_UnitProperty				UnitPropertyCondition;
	local X2Effect_PersistentStatChange			DisorientedEffect;
	local X2Effect_Panicked						PanickedEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.StrafingRun_A10_Stage2_FinalAbilityName);
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

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

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

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
	DamageEffect.bApplyWorldEffectsForEachTargetLocation = true;
	Template.AddMultiTargetEffect(DamageEffect);

	if (default.StrafingRun_A10_Panic_Enable)
	{

		//  Panic effect
		PanickedEffect = class'X2StatusEffects'.static.CreatePanickedStatusEffect();
		PanickedEffect.iNumTurns = default.StrafingRun_A10_Panic_NumOfTurns;
		PanickedEffect.MinStatContestResult = 2;
		PanickedEffect.MaxStatContestResult = 3;
		Template.AddTargetEffect(PanickedEffect);

	}

	if (default.StrafingRun_A10_Disorient_Enable)
	{
		//  Disorient effect
		DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect();
		DisorientedEffect.iNumTurns = default.StrafingRun_A10_Disorient_NumOfTurns;
		DisorientedEffect.MinStatContestResult = 1;
		DisorientedEffect.MaxStatContestResult = 1;
		Template.AddTargetEffect(DisorientedEffect);
	}

	Template.ActionFireClass = class'X2Action_MortarStrikeStageTwo';
	Template.bSkipExitCoverWhenFiring = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.LostSpawnIncreasePerUse = default.StrafingRun_A10_LostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

defaultproperties
{
	StrafingRun_A10_Stage2_FinalAbilityName		= "Ability_Support_Land_Off_StrafingRun_A10_Stage2"
	StrafingRun_A10_Stage2_FinalTriggerName		= "Trigger_Support_Land_Off_StrafingRun_A10_Stage2"
	StrafingRun_A10_Stage1_LocSelectEffectName	= "Effect_Support_Land_Off_StrafingRun_A10_Stage1"
}